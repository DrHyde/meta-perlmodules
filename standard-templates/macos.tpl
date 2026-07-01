on:
  push:
    paths:
      - '.github/workflows/macos.yml'
      - '.github/workflows/run-macos'

#include no-concurrency.inc
name: $template_var{workflow_human_name} || "MacOS"

jobs:
  build:
    #include dont-autotest-dependabot.inc
    #include $template_var{workflow_file_name}/runs-on.inc
    steps:
      - uses: actions/checkout@v6
      - name: Setup Perl environment
        uses: shogo82148/actions-setup-perl@v1
      - name: Test and build
        run: |
          #include $template_var{workflow_file_name}/extra-modules.inc || null
          #include pre-configure-CPAN-dist.inc || null
          #include $template_var{workflow_file_name}/configure-test-CPAN-dist.inc || configure-test-CPAN-dist-with-eumm.inc
