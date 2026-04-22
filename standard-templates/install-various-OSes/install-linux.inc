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
      #include install-various-OSes/set-env-vars-for-install-linux.inc || null
      run: |
        #include install-various-OSes/install-linux/custom-install-tar-gz.inc || cpanm-install-tar-gz.inc
