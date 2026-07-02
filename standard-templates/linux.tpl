on:
  push:
    paths:
      - '.github/workflows/$template_var{workflow_file_name}.yml'
      - '.github/workflows/run-$template_var{workflow_file_name}'

#include no-concurrency.inc
name: $template_var{workflow_human_name} || "Linux"

jobs:
  list:
    #include dont-autotest-dependabot.inc
    name: list available perl versions
    runs-on: 'ubuntu-latest'
    steps:
      - uses: shogo82148/actions-setup-perl@v1
      #include linux/set-perls-matrix.inc
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
  build:
    runs-on: 'ubuntu-latest'
    needs: list
    strategy:
      fail-fast: false
      matrix: ${{fromJson(needs.list.outputs.matrix)}}
    name: Perl ${{ matrix.perl }}
    steps:
      - name: check out code
        uses: actions/checkout@v7

      - name: switch to perl ${{ matrix.perl }}
        uses: shogo82148/actions-setup-perl@v1
        with:
          perl-version: ${{ matrix.perl }}

      - name: run tests
        #include $template_var{workflow_file_name}/env.inc || linux/env.inc
        run: |
            perl -v
            #include $template_var{workflow_file_name}/extra-dependencies.inc || null
            #include pre-configure-CPAN-dist.inc || null
            #include $template_var{workflow_file_name}/configure-test-CPAN-dist.inc || configure-test-CPAN-dist-with-eumm.inc
