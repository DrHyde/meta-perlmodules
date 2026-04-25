on:
  push:
    paths:
      - '.github/workflows/macos.yml'
      - '.github/workflows/run-macos'
name: $template_var{workflow_human_name} || "MacOS"

jobs:
  build:
    #include $template_var{workflow_file_name}/runs-on.inc
    steps:
      - uses: actions/checkout@v6
      - name: Setup Perl environment
        uses: shogo82148/actions-setup-perl@v1
      - name: Test and build
        run: |
          #include $template_var{workflow_file_name}/extra-modules.inc || null
          #include configure-test-CPAN-dist-with-eumm.inc
