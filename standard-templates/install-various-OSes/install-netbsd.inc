install-netbsd:
  runs-on: 'ubuntu-latest'
  needs: build
  steps:
    - uses: actions/download-artifact@v8.0.1
      with:
        name: dist-for-install
    - name: Install on NetBSD
      uses: cross-platform-actions/action@v0.32.0
      with:
        operating_system: netbsd
        version: 10.1
        shell: bash
        run: |
          echo "PKG_PATH=https://cdn.netbsd.org/pub/pkgsrc/packages/NetBSD/amd64/10.1/All" | sudo tee -a /etc/pkg_install.conf &&
          sudo pkgin -y update &&
          sudo pkgin -y install perl &&
          mkdir dist-for-test &&
          tar -C dist-for-test -xzf *.tar.gz &&
          cd dist-for-test/* && # sudo pkg install -y perl5 &&
          perl -MCPAN -e 'install qw(App::cpanminus)' &&
          /home/runner/perl5/bin/cpanm --installdeps . &&
          /home/runner/perl5/bin/cpanm -v .
