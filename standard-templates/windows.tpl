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
        - latest
        - '5.24'
        - '5.26'
        - '5.28'
        - '5.30'
        - '5.32'
        - '5.34'
        - '5.36'
        - '5.38'
        - '5.40'
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
