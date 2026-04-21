install-linux:
  runs-on: 'ubuntu-latest'
  needs: build
  container:
    image: perl:5.34
  steps:
    - uses: actions/download-artifact@v8.0.1
      with:
        name: dist-for-install
    - name: Install on Linux
      run: |
        cpanm *.tar.gz
