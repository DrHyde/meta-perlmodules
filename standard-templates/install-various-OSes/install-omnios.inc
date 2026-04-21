install-omnios:
  runs-on: 'ubuntu-latest'
  needs: build
  steps:
    - uses: actions/download-artifact@v8.0.1
      with:
        name: dist-for-install
    - name: Install on OmniOS
      uses: cross-platform-actions/action@v0.32.0
      with:
        operating_system: omnios
        version: r151056
        shell: bash
        run: |
          sudo pkg install archiver/gnu-tar developer/gcc14 &&
          mkdir dist-for-test &&
          sudo ln -sf $(which gtar) $(which tar) &&
          gtar -C dist-for-test -xzf *.tar.gz &&
          cd dist-for-test/* &&
          cpan App::cpanminus &&
          /home/runner/perl5/bin/cpanm --installdeps . &&
          /home/runner/perl5/bin/cpanm -v .
