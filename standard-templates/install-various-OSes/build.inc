build:
  runs-on: 'macos-latest'
  steps:
    - uses: actions/checkout@v6
    - name: Setup Perl environment
      uses: shogo82148/actions-setup-perl@v1
    - name: Test and build
      run: |
        cpanm --installdeps .
        #include build-CPAN-dist-custom.inc || build-CPAN-dist-with-eumm.inc
    - uses: actions/upload-artifact@v7
      with:
        name: dist-for-install
        path: '*.tar.gz'
        retention-days: 1
