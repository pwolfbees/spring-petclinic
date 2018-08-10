#!/bin/sh
set -e

if [ $# -ne 3 ];
    then echo "Usage: sign-attestation.sh <path to service acct key> <path to attestor private key> <attestor name> <attestor email> <attestation project> <image:tag>"
    exit 1
fi

#check if gpg is installed locally and install if not
if ! ( hash gpg 2>/dev/null ); then 
  apt-get update apt-get install gnupg2 -y
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
#generate full url of the image to sign
artifact_url="$(gcloud container images describe $6 --format='value(image_summary.fully_qualified_digest)')"
#import the private key from attestor 
gpg --allow-secret-key-import --import $2
#create signature from payload of image
gpg --local-user $4 --armor --output /tmp/generated_signature.pgp --sign "$(gcloud beta container binauthz create-signature-payload --artifact-url=$artifact_url)"
# create attestation using signature created
gcloud beta container binauthz attestations create --artifact-url="$artifact_url" --attestor="projects/$5/attestors/$3}" --signature-file=/tmp/generated_signature.pgp --pgp-key-fingerprint="$(gpg --with-colons --fingerprint $4 | awk -F: '$1 == "fpr" {print $10;exit}')"