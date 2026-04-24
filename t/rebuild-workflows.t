use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path remove_tree);
use File::Spec;
use File::Temp qw(tempdir);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my $repo_root = abs_path(File::Spec->catdir(dirname(__FILE__), '..'));
my $script    = File::Spec->catfile($repo_root, 'rebuild-workflows');
my $fixtures  = File::Spec->catdir($repo_root, 't', 'templates');

sub copy_tree {
    my($from, $to) = @_;
    return unless(-d $from);

    find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $source = $File::Find::name;
                return if($source eq $from);

                my $relative = File::Spec->abs2rel($source, $from);
                my $target = File::Spec->catfile($to, $relative);

                if(-d $source) {
                    make_path($target);
                    return;
                }

                make_path(dirname($target));
                copy($source, $target) || die("Couldn't copy $source to $target: $!");
            },
        },
        $from,
    );
}

sub copy_script {
    my $target = shift;

    make_path(dirname($target));
    copy($script, $target) || die("Couldn't copy $script to $target: $!");
    chmod(0755, $target) || die("Couldn't chmod $target: $!");
}

sub slurp {
    my $file = shift;
    open(my $fh, '<', $file) || die("Couldn't read $file: $!");
    local $/;
    return <$fh>;
}

sub with_chdir {
    my($dir, $code) = @_;
    my $starting_dir = getcwd();
    chdir($dir) || die("Couldn't chdir to $dir: $!");
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    chdir($starting_dir) || die("Couldn't chdir back to $starting_dir: $!");
    die($error) unless($ok);
}

sub run_script {
    my(%args) = @_;
    my($stdout, $stderr, $exit_code);

    with_chdir(
        $args{cwd},
        sub {
            local %ENV = (%ENV, %{ $args{env} || {} });
            my $err = gensym;
            my $pid = open3(
                undef,
                my $out,
                $err,
                @{ $args{command} },
            );
            $stdout = do { local $/; <$out> // q{} };
            $stderr = do { local $/; <$err> // q{} };
            waitpid($pid, 0);
            $exit_code = $? >> 8;
        },
    );

    return {
        exit   => $exit_code,
        output => $stdout.$stderr,
    };
}

sub make_repo {
    my($fixture_name, %args) = @_;
    my $repo;
    if($ENV{REBUILD_WORKFLOW_TEST_BASE}) {
        $repo = File::Spec->catdir($ENV{REBUILD_WORKFLOW_TEST_BASE}, 'repo');
        remove_tree($repo) if(-e $repo);
        make_path($repo);
    } else {
        $repo = tempdir(CLEANUP => 1);
    }
    my $script_dir = $args{script_dir} || 'support';
    my $script_path = File::Spec->catfile($repo, $script_dir, 'rebuild-workflows');

    make_path(File::Spec->catdir($repo, 'bin'));
    make_path(File::Spec->catdir($repo, '.github', 'workflows'))
        unless($args{omit_workflows_dir});
    make_path(File::Spec->catdir($repo, 'workflow-templates'))
        unless($args{omit_template_dir});

    copy_script($script_path);

    if(!$args{omit_standard_templates}) {
        copy_tree(
            File::Spec->catdir($fixtures, $fixture_name, 'standard-templates'),
            File::Spec->catdir($repo, $script_dir, 'standard-templates'),
        );
    }

    if(!$args{omit_template_dir}) {
        copy_tree(
            File::Spec->catdir($fixtures, $fixture_name, 'workflow-templates'),
            File::Spec->catdir($repo, 'workflow-templates'),
        );
    }

    if(!$args{omit_symlinks}) {
        symlink('../support/rebuild-workflows', File::Spec->catfile($repo, 'bin', 'relative-runner'))
            || die("Couldn't create relative symlink: $!");
        symlink(File::Spec->catfile($repo, 'support', 'rebuild-workflows'), File::Spec->catfile($repo, 'abs-runner'))
            || die("Couldn't create absolute symlink: $!");
    }

    for my $unreadable (
        File::Spec->catfile($repo, 'workflow-templates', 'unreadable-root.yml'),
        File::Spec->catfile($repo, 'support', 'standard-templates', 'unreadable.inc'),
    ) {
        next unless(-e $unreadable);
        chmod(0000, $unreadable) || die("Couldn't chmod $unreadable: $!");
    }

    return $repo;
}

{
    my $repo = make_repo('success');
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
        env     => {
            REBUILD_WORKFLOW_DEBUG => 1,
        },
    );

    is($result->{exit}, 0, 'relative binary path succeeds');
    like($result->{output}, qr/Processing workflow-templates\/success\.yml/, 'logs the file being processed');
    like($result->{output}, qr/found \#include: local\.inc/, 'logs includes without alternatives');
    like($result->{output}, qr/found \#include: missing\.inc \Q||\E fallback\.inc/, 'logs includes with alternatives');
    like($result->{output}, qr/processed local\.inc/, 'logs project includes when debug is enabled');
    like($result->{output}, qr/processed 'null'/, 'logs null fallbacks when debug is enabled');

    is(
        slurp(File::Spec->catfile($repo, '.github', 'workflows', 'success.yml')),
        <<'END_EXPECTED',
# Auto-generated file, see workflow-templates/success.yml

name: success
jobs:
  build:
    steps:
      - run: |
          local line 1
          local line 2
          shared line
          fallback line
          fallback after unreadable
          recursive line
END_EXPECTED
        'writes the expanded workflow file',
    );
}

{
    my $repo = make_repo('success');
    my $result = run_script(
        cwd     => $repo,
        command => [File::Spec->catfile($repo, 'support', 'rebuild-workflows')],
    );

    is($result->{exit}, 0, 'absolute binary path succeeds');
}

{
    my $repo = make_repo('success');
    my $result = run_script(
        cwd     => $repo,
        command => ['bin/relative-runner'],
    );

    is($result->{exit}, 0, 'relative symlink path succeeds');
}

{
    my $repo = make_repo('success');
    my $result = run_script(
        cwd     => $repo,
        command => [File::Spec->catfile($repo, 'abs-runner')],
    );

    is($result->{exit}, 0, 'absolute symlink path succeeds');
}

{
    my $repo = make_repo('success', omit_workflows_dir => 1, omit_template_dir => 1, omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'missing repo layout fails when both directories are absent');
    like(
        $result->{output},
        qr/This should be run from the root of a git checkout, which has \.github\/workflows and workflow-templates/,
        'reports missing repo layout',
    );
}

{
    my $repo = make_repo('success', omit_template_dir => 1, omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'missing workflow-templates fails');
}

{
    my $repo = make_repo('success', script_dir => 'missing', omit_standard_templates => 1, omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['missing/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'missing shared templates fails');
    like($result->{output}, qr/Can't find standard templates for /, 'reports missing shared templates');
}

{
    my $repo = make_repo('missing-include', omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'missing include fails');
    like($result->{output}, qr/Couldn't \#include missing\.inc/, 'reports the missing include');
}

{
    my $repo = make_repo('read-failure', omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'unreadable workflow template fails');
    like($result->{output}, qr/Couldn't read workflow-templates\/unreadable-root\.yml:/, 'reports an unreadable root template');
}

{
    my $repo = make_repo('write-failure', omit_symlinks => 1);
    my $result = run_script(
        cwd     => $repo,
        command => ['support/rebuild-workflows'],
    );

    isnt($result->{exit}, 0, 'missing output subdirectory fails');
    like($result->{output}, qr/Couldn't write \.github\/workflows\/nested\/broken\.yml/, 'reports an unwritable output target');
}

done_testing();
