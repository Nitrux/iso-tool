#! /bin/sh

# -- Exit on errors.

set -x

### Download Maui AppImages
echo "[global]
default = opencode
[opencode]
url = http://www.opencode.net/
private_token = $OPENCODE_API_TOKEN
api_version = 4
" > /tmp/python-gitlab.cfg

gitlab=$(echo "$(which gitlab) -c /tmp/python-gitlab.cfg")

LATEST_PIPELINE_ID=$($gitlab project-pipeline list --project-id 918 | head -n 1 | tr -d 'id: ')
LATEST_JOBS=$($gitlab project-pipeline-job list --project-id 918 --pipeline-id $LATEST_PIPELINE_ID | grep -Ev "^$" | tr -d "id: ")

mkdir -p maui_pkgs
mkdir -p $BUILD_DIR/maui_debs

pushd maui_pkgs
    for i in $LATEST_JOBS; do
        curl --output artifacts.zip --header "PRIVATE-TOKEN: $OPENCODE_API_TOKEN" "https://www.opencode.net/api/v4/projects/918/jobs/$i/artifacts"
        unzip artifacts.zip
        rm artifacts.zip
    done
    
    mv index-*amd64*.deb $BUILD_DIR/maui_debs
    mv buho-*amd64*.deb $BUILD_DIR/maui_debs
    mv nota-*amd64*.deb $BUILD_DIR/maui_debs
    mv vvave-*amd64*.deb $BUILD_DIR/maui_debs
    mv station-*amd64*.deb $BUILD_DIR/maui_debs
    mv pix-*amd64*.deb $BUILD_DIR/maui_debs
    mv mauikit-*amd64*.deb $BUILD_DIR/maui_debs
        
    ls -l $BUILD_DIR/maui_debs
popd

rm -rf maui_pkgs
###
