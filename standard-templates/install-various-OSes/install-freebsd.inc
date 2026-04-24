install-freebsd:
  runs-on: ubuntu-latest
  needs: build
  steps:
    - uses: actions/download-artifact@v8.0.1
      with:
        name: dist-for-install
    - name: Install on FreeBSD
      #include install-various-OSes/set-env-vars-for-install-freebsd.inc || null
      uses: cross-platform-actions/action@v1.0.0
      with:
        operating_system: freebsd
        version: 14.2
        shell: bash
        run: |
          mkdir dist-for-test &&
          tar -C dist-for-test -xzf *.tar.gz &&
          cd dist-for-test/* &&
          sudo pkg install -y perl5 &&
          cpan App::cpanminus &&
          /home/runner/perl5/bin/cpanm --installdeps . &&
          /home/runner/perl5/bin/cpanm -v .
