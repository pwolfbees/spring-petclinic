#!/bin/sh
set -e

# args
# 1 path to service account that has access to deploy

if [ $# -ne 1 ];
    then echo "Usage: gcloud-credentials.sh <path to service acct key>"
    exit 1
fi

#check if gcloud is installed and install it if not
if ! ( hash gcloud 2>/dev/null ); then
  export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
  echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  apt-get update && apt-get install google-cloud-sdk -y
fi

#authenticate service accout with required permissions to sign attestation
gcloud auth activate-service-account --key-file=$1 --no-user-output-enabled