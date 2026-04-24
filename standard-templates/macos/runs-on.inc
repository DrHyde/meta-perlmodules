strategy:
  fail-fast: false
  matrix:
    runs-on: ['macos-26', 'macos-14', 'macos-15']
runs-on: ${{ matrix.runs-on }}
