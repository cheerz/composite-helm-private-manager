
# composite-helm-private-manager

## Introduction

This repository is a [BASH Github action composite](https://docs.github.com/en/free-pro-team@latest/actions/learn-github-actions/finding-and-customizing-actions) created with that [Documentation](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions)
The goal of that custom action is to check and publish a list of [helm chart](https://helm.sh/docs/topics/charts/) to a [chartMuseum repository](https://github.com/helm/chartmuseum)

## Usage
Call use ( for @version please refer to [release list](https://github.com/cheerz/composite-helm-private-manager/releases))
```yaml
- uses: cheerz/composite-helm-private-manager@v1.0.0
```
Inputs :
```yaml
  with:
    chart-paths: <SPACE_SEPARATED_LIST_OF_HELM_CHART_PATH>
    chart-status: <CREATED||UPDATED||DELETED>
    chart-repository-url: <URL_OF_YOUR_CHART_REPOSITORY>
```
### nota 
For `chart-paths` the script will always search for `Chart.yml` or `Chart.yaml` file ( case sensible )

## Exemple
#### Basic hard coded exemple
```yaml
charts-management:
  needs: prepare
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@master
    - uses: cheerz/composite-helm-private-manager@dev
      with:
      chart-paths: "charts/web-application/Chart.yaml charts/worker-application/Chart.yml"
      chart-status: "created"
        chart-repository-url: "https://charts.exemple.net"
```
#### More advanced version with  changed file 
```yaml
name: Apply all basic config for kubernetes
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      modified_chart_list: ${{ steps.updated_Charts.outputs.find-charts }}
    steps:
      - uses: actions/checkout@master
      - uses: jitterbit/get-changed-files@v1
        id: changed_files
      - name: search_updated_chart
        id: updated_Charts
        run: |
        files="${{ steps.changed_files.outputs.modified }}"
        findCharts=()
        for chart in $files; do
          if [[ $chart == *"/Chart.yaml"* ]] || [[ $chart == *"/Chart.yml"* ]]; then
            findCharts+=( "$chart" )
          fi
        done
        echo "::set-output name=find-charts::$(echo $findCharts)"
  charts-management:
    needs: prepare
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@master
      - uses: cheerz/composite-helm-private-manager@dev
        with:
        chart-paths: "${{ needs.prepare.outputs.modified_chart_list }}"
        chart-status: "updated"
          chart-repository-url: "https://charts.exemple.net"
```
So some important points :
 1. The application is split in two job because you can reproduce and multiply composite for deleted and added charts  
 2. I use [jitterbit get-changed-files](https://github.com/jitterbit/get-changed-files)it work very well
 3. The step `updated_Charts` is bash scripts who search specific updated file to created a compliant list (I think I will try to ehance that part)
 4. we get the prepared list from [ouput mechanism](https://docs.github.com/en/free-pro-team@latest/actions/creating-actions/metadata-syntax-for-github-actions#outputs) with `"${{ needs.prepare.outputs.modified_chart_list }}"`
 5. Don't forget to change `chart-repository-url`

## Release management
Release management on that project is simple
If you push on master, a release will be created under the `dev` tag
```yaml
  - uses: cheerz/composite-helm-private-manager@dev
```
If you add and push a tag on format `vx.x.x` it will create a release from that tag
Exemple:
`git tag -a v1.17.2`
`git push --tags`
```yaml
  - uses: cheerz/composite-helm-private-manager@v1.17.2
```
## Upcoming development
* Implement delete function ( not working for now )
* Fault toleration ( for now the script stop if something go wrong with one value )
* Improve `updated_Charts` step to remove bash ( or hide it somewhere else maybe )

## License
The scripts and documentation in this project are released under the [MIT License](https://github.com/cheerz/composite-helm-private-manager/blob/master/LICENSE)