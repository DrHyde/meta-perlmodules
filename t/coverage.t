use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Path qw(remove_tree);
use File::Spec;
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my $repo_root = abs_path(File::Spec->catdir(dirname(__FILE__), '..'));
my $db_dir    = File::Spec->catdir($repo_root, 'cover_db');
my $html_file = File::Spec->catfile($db_dir, 'coverage.html');
my $fixture_root = File::Spec->catdir($db_dir, 'test-fixtures');
my $fixture_repo = File::Spec->catdir($fixture_root, 'repo');

sub with_chdir {
    my($dir, $code) = @_;
    my $starting_dir = getcwd();
    chdir($dir) || die("Couldn't chdir to $dir: $!");
    my $ok = eval { $code->(); 1 };
    my $error = $@;
    chdir($starting_dir) || die("Couldn't chdir back to $starting_dir: $!");
    die($error) unless($ok);
}

sub run_command {
    my(%args) = @_;
    my @command = @{ $args{command} };
    my($stdout, $stderr, $exit_code);

    with_chdir(
        $args{cwd} || $repo_root,
        sub {
            my $err = gensym;
            my $pid = open3(undef, my $out, $err, @command);
            $stdout = do { local $/; <$out> // q{} };
            $stderr = do { local $/; <$err> // q{} };
            waitpid($pid, 0);
            $exit_code = $? >> 8;
        },
    );

    return {
        exit   => $exit_code,
        stdout => $stdout,
        stderr => $stderr,
    };
}

{
    remove_tree($db_dir) if(-e $db_dir);

    local $ENV{PERL5OPT} = join(
        q{ },
        grep { defined && length }
            ($ENV{PERL5OPT}, "-MDevel::Cover=-db,$db_dir,-coverage,statement,branch,condition"),
    );
    local $ENV{REBUILD_WORKFLOW_TEST_BASE} = $fixture_root;

    my $prove = run_command(command => ['prove', '-v', 't/rebuild-workflows.t']);
    is($prove->{exit}, 0, 'fixture tests pass under Devel::Cover')
        || diag($prove->{stdout}.$prove->{stderr});
}

{
    local $ENV{PERL5OPT};

    my $html = run_command(
        cwd     => $fixture_repo,
        command => ['cover', '-report', 'html_basic', $db_dir],
    );
    is($html->{exit}, 0, 'cover generates an HTML report')
        || diag($html->{stdout}.$html->{stderr});
    ok(-f $html_file, 'HTML coverage report is written to cover_db');

    my $cover = run_command(
        cwd     => $fixture_repo,
        command => ['cover', '-report', 'text', '-select_re', '^support/rebuild-workflows$', $db_dir],
    );
    is($cover->{exit}, 0, 'cover generates a text summary')
        || diag($cover->{stdout}.$cover->{stderr});
    like(
        $cover->{stdout},
        qr{(?:^|\n)Total\s+100(?:\.0+)?\s+100(?:\.0+)?\s+100(?:\.0+)?(?:\s|$)}m,
        'rebuild-workflows has 100% statement, branch, and condition coverage',
    );
}

done_testing();
