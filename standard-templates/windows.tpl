name: Windows
on:
  push:
    paths:
      - '.github/workflows/windows.yml'
      - '.github/workflows/run-windows'
jobs:
  build:
    runs-on: windows-latest
    strategy:
      fail-fast: false
      matrix:
        perl-version:
        #include windows/perl-versions.inc
    steps:
    - uses: actions/checkout@v6
    - name: Set up perl
      uses: shogo82148/actions-setup-perl@v1
      with:
        distribution: strawberry
        perl-version: ${{ matrix.perl-version }}
    - name: perl -V
      run: perl -V
    - name: Install deps and test
      run: |
        #include pre-configure-CPAN-dist.inc || null
        #include $template_var{workflow_file_name}/configure-test-CPAN-dist.inc
