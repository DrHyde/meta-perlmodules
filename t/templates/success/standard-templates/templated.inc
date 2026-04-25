$template_var{workflow_file_name}
$template_var{animal}
$template_var{colour} || "blue"
null default: <$template_var{blank_line} || null>
#include $template_var{workflow_file_name}/nested.inc adjective = "$template_var{adjective}"
