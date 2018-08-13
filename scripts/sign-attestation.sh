#!/bin/sh
set -e

if [ $# -ne 6 ];
    then echo "Usage: sign-attestation.sh <path to service acct key> <path to attestor private key> <attestor name> <attestor email> <attestation project> <image:tag>"
    exit 1
fi

# args
# 1 path to service account that has access to deploy
$SVC_ACCT=$1
# 2 path to the private key of the attestor
$ATTESTOR_PRIVATE_KEY=$2
# 3 name of the attestor to use
$ATTESTOR_NAME=$3
# 4 email address of the attestor
$ATTESTOR_EMAIL=$4
# 5 project that contains attestations
$ATTESTOR_PROJECT=$5
# 6 Full image url and tag of container to deploy
$DEPLOY_IMAGE=$6

#check if gpg is installed locally and install if not
if ! ( hash gpg 2>/dev/null ); then 
  apt-get update apt-get install gnupg2 -y
fi

# authenticate service accout with required permissions to sign attestation
./gcloud-credentials.sh $SVC_ACCT
# generate full url of the image to sign
artifact_url="$(gcloud container images describe $DEPLOY_IMAGE --format='value(image_summary.fully_qualified_digest)')"
# import the private key from attestor 
gpg --allow-secret-key-import --import $ATTESTOR_PRIVATE_KEY
# create signature from payload of image
gpg --local-user $ATTESTOR_EMAIL --armor --output /tmp/generated_signature.pgp --sign "$(gcloud beta container binauthz create-signature-payload --artifact-url=$artifact_url)"
# create attestation using signature created
gcloud beta container binauthz attestations create --artifact-url="$artifact_url" --attestor="projects/$ATTESTOR_PROJECT/attestors/$ATTESTOR_NAME}" --signature-file=/tmp/generated_signature.pgp --pgp-key-fingerprint="$(gpg --with-colons --fingerprint $ATTESTOR_EMAIL | awk -F: '$1 == "fpr" {print $10;exit}')"