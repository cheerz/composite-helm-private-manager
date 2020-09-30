#!/bin/bash

##############################################################
####################### VARIABLE #############################
##############################################################
chartPath=$1;
chartStatus=$2;
ChartRepositoryUrl=$3
chartVersion="0.0.0"
chartFileName="Chart.yaml"
check_chart_structure_result=false
check_chart_version_exist_result=true
push_chart_result="0"


##############################################################
####################### FUNCTIONS ############################
##############################################################

# check basic need for chart package
check_chart_structure () {
  if [ -d "$1/" ]; then
    if [ -d "$1/templates" ]; then
      if [ -f "$1/Chart.yaml" ] || [ -f "$1/Chart.yml" ] ; then
        check_chart_structure_result=true
      else
        >&2 echo "Chart do not have main chart descriptor file (Chart.yaml or Chart.yml)"
      fi
    else
      >&2 echo "Chart do not have template sub folder"
    fi
  else
    >&2 echo "Chart folder $1/ do not exist"  
  fi
}

check_chart_version_exist () {
  statusCode=$(curl -s -o /dev/null -w "%{http_code}" ${1}/api/charts/${2}/${3})
  if [[ $statusCode == 404 ]]; then
    check_chart_version_exist_result=false
  fi
}

# simple function who send package trought curl command
push_chart () {
  push_chart_result=$(curl -s -o /dev/null -w "%{http_code}" --data-binary "@${2}-${3}.tgz" ${1}/api/charts)
}

# generic function to parse yaml found here : https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
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


##############################################################
######################## PRE CHECK ###########################
##############################################################

# check chart path and correct it if needed
if [[ $chartPath == *"/Chart.yml"* ]]; then
  chartFileName="Chart.yml"
fi
chartPath=${chartPath%"/$chartFileName"}
chartPath="$BASE_WORKING_PATH/$chartPath"

# Not mandatory check, mainly for help debug purpose
if [[ "deleted created updated" != *"$chartStatus"* ]]
then
    >&2 echo "Unrecognised status, please set one of the following value : deleted, created, updated"
    exit 1;
fi


##############################################################
########################## DELETE ############################
##############################################################

# check the chart himself
if [ $chartStatus == "deleted" ]; then
    if [ -d "$chartPath" ]; then
        >&2 echo "You try to delete an existing chart"
        exit 1;
    else
      echo "here normally we delete the chart (TO DO)"
    fi
fi


##############################################################
################## CREATED AND UPDATE ########################
##############################################################

# Here we manage created and updated chart at the same way
if [ $chartStatus == "created" ] || [ $chartStatus == "updated" ]; then
    # Little folder structure check to verify it's a complete helm chart
    check_chart_structure $chartPath
    if [[ $check_chart_structure_result == true ]]; then
      #Parse the main chart file to get basic information
      eval $(parse_yaml "$chartPath/$chartFileName" CHART_)
      # We create the package with helm command line
      helm package "$chartPath/"
      # we check if the package do not already exist in that version
      check_chart_version_exist $ChartRepositoryUrl $CHART_name $CHART_version
      if [[ $check_chart_version_exist_result == false ]]; then
        chartVersion=$CHART_version
        # Push the chart to chartmuseum repository
        push_chart $ChartRepositoryUrl $CHART_name $CHART_version $chartPath
        if [[ $push_chart_result != 201 ]]; then
          >&2 echo "Failed to push Chart ${CHART_name} in version ${CHART_version}, unknow error CODE : ${pushResult}"
          exit 1;
        fi
      else
        >&2 echo "Chart ${CHART_name} already exist in version ${CHART_version}"
        exit 1;
      fi
    else
        >&2 echo "CREATED chart check structure failed"
        exit 1;
    fi
fi


##############################################################
########################## OUPUT #############################
##############################################################

# output
echo "::set-output name=chart-path::$(echo $chartPath)"
echo "::set-output name=chart-file-name::$(echo $chartFileName)"
echo "::set-output name=chart-version::$(echo $chartVersion)"