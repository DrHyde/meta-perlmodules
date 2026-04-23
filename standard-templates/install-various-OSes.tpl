on: [push, pull_request]
name: Install on various OSes
jobs:
  #include install-various-OSes/build.inc
  #include install-various-OSes/install-linux.inc
  #include install-various-OSes/install-netbsd.inc
  #include install-various-OSes/install-freebsd.inc
  #include install-various-OSes/install-openbsd.inc
  #include install-various-OSes/install-omnios.inc
  #include install-various-OSes/extra-platforms.inc || null
