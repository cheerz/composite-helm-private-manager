#declarative function for global structure check
check_chart_structure () {
  if [ -d "$1" ]; then
    if [ -d "$1/templates" ]; then
        if [ -f "$1/Chart.yaml" ] || [ -f "$1/Chart.yml" ] ; then
            return 1;
        else
            >&2 echo "Chart do not have main chart descriptor file (Chart.yaml or Chart.yml)"
        fi
    else
        >&2 echo "Chart do not have template sub folder"
    fi
  else
    >&2 echo "Chart folder $1 do not exist"  
  fi
  return 0;
}

check_chart_version_exist () {
    statusCode=$(curl -s -o /dev/null -w "%{http_code}" ${1}/api/charts/${2}/${3})
    if statusCode == 404; then
        return 0;
    fi
    return 1;
}

push_chart () {
    return $(curl -s -o /dev/null -w "%{http_code}" curl --data-binary "@${2}-${3}.tgz" ${1}/api/charts)
}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}