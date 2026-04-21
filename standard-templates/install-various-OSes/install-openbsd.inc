install-openbsd:
  runs-on: ubuntu-latest
  needs: build
  steps:
    - uses: actions/download-artifact@v8.0.1
      with:
        name: dist-for-install
    - name: Install on OpenBSD
      uses: cross-platform-actions/action@v0.32.0
      with:
        operating_system: openbsd
        version: 7.4
        shell: bash
        run: |
          mkdir dist-for-test &&
          tar -C dist-for-test -xzf *.tar.gz &&
          cd dist-for-test/* &&
          cpan App::cpanminus &&
          /home/runner/perl5/bin/cpanm --quiet --notest --installdeps . &&
          /home/runner/perl5/bin/cpanm -v .
