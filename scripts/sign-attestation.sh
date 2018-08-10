#!/bin/sh
set -e

# args
# 1 path to service account that has access to deploy
# 2 path to the private key of the attestor
# 3 name of the attestor to use
# 4 email address of the attestor
# 5 project that contains attestations
# 6 Full image url and tag of container to deploy

if [ $# -ne 6 ];
    then echo "Usage: sign-attestation.sh <path to service acct key> <path to attestor private key> <attestor name> <attestor email> <attestation project> <image:tag>"
    exit 1
fi

#check if gpg is installed locally and install if not
if ! ( hash gpg 2>/dev/null ); then 
  apt-get update apt-get install gnupg2 -y
fi

# authenticate service accout with required permissions to sign attestation
./gcloud-credentials.sh $1 
# generate full url of the image to sign
artifact_url="$(gcloud container images describe $6 --format='value(image_summary.fully_qualified_digest)')"
# import the private key from attestor 
gpg --allow-secret-key-import --import $2
# create signature from payload of image
gpg --local-user $4 --armor --output /tmp/generated_signature.pgp --sign "$(gcloud beta container binauthz create-signature-payload --artifact-url=$artifact_url)"
# create attestation using signature created
gcloud beta container binauthz attestations create --artifact-url="$artifact_url" --attestor="projects/$5/attestors/$3}" --signature-file=/tmp/generated_signature.pgp --pgp-key-fingerprint="$(gpg --with-colons --fingerprint $4 | awk -F: '$1 == "fpr" {print $10;exit}')"