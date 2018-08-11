#!/bin/sh

set -e

. configuration

gcloud config set project $DEPLOYER_PROJECT_ID

# ensure that the required apis are enabled
echo "Enabling required apis on project"
gcloud services enable container.googleapis.com containeranalysis.googleapis.com binaryauthorization.googleapis.com

./container-analysis-setup.sh
./attestor-setup.sh
./cloudbees-setup.sh
./cleansh.sh