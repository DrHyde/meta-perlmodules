- id: set-matrix
  name: list available perl versions
  shell: perl {0}
  run: |
    use Actions::Core;
    #include $template_var{workflow_file_name}/set-perls-matrix-custom.inc || linux/set-perls-matrix-default.inc
