#!/bin/bash
chartPath=$1;
chartStatus=$2;
ChartRepositoryUrl=$3
chartVersion="0.0.0"
chartFileName="Chart.yaml"

source $(dirname "$0")/function.sh


# check chart path and correct it if needed
if [[ $chartPath == *"/Chart.yml"* ]]; then
  chartFileName="Chart.yml"
fi
echo $chartPath
chartPath=${chartPath%"/$chartFileName"}
echo $chartPath
chartPath="$BASE_WORKING_PATH/$chartPath"
echo $chartPath
echo $GITHUB_EVENT_PATH

echo "================ DEBUG ===================="
echo "DIR . "
echo $(ls -lah)
echo "DIR BASE_WORKING_PATH "
echo $(ls -lah $BASE_WORKING_PATH)
echo "DIR chartPath "
echo $(ls -lah $chartPath)
echo "DIR GITHUB_EVENT_PATH "
echo $(ls -lah $GITHUB_EVENT_PATH)
echo "=============== END DEBUG ================="

# Not mandatory check, mainly for help debug purpose
if [[ "deleted created updated" != *"$chartStatus"* ]]
then
    >&2 echo "Unrecognised status, please set one of the following value : deleted, created, updated"
    exit 1;
fi



# check the chart himself
if [ $chartStatus == "deleted" ]; then
    if [ -d "$chartPath" ]; then
        >&2 echo "You try to delete an existing chart"
        exit 1;
    else
      echo "here normally we delete the chart (TO DO)"
    fi
fi

if [ $chartStatus == "created" ] || [ $chartStatus == "updated" ]; then
    check_struct="$(check_chart_structure $chartPath)"
    if [[ $check_struct == 1 ]]; then
      eval $(parse_yaml "$chartPath/$chartFileName" CHART_)
      helm package "$chartPath/"
      charVersionExist="$(check_chart_version_exist $ChartRepositoryUrl $CHART_name $CHART_version)"
      if [[ $charVersionExist == 0 ]]; then
        chartVersion=$CHART_version
        pushResultCode="$(push_chart $ChartRepositoryUrl $CHART_name $CHART_version)"
        if [ pushResult != 201]; then
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


# output
echo "::set-output name=chart-path::$(echo $chartPath)"
echo "::set-output name=chart-file-name::$(echo $chartFileName)"
echo "::set-output name=chart-version::$(echo $chartVersion)"