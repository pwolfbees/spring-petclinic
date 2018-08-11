#!/bin/sh

set -e

# Refer to latest Documentation for help
# https://cloud.google.com/binary-authorization/docs/creating-attestors

. configuration

echo "generating public and private key for attestor account $ATTESTOR_EMAIL"
gpg --batch --gen-key <(
  cat <<- EOF
    Key-Type: RSA
    Key-Length: 2048
    Name-Real: "${ATTESTOR_NAME}"
    Name-Email: "${ATTESTOR_EMAIL}"
    %commit
EOF
)

echo "exporting attestor keys"
gpg --export-secret-key -a ${ATTESTOR_NAME} > /tmp/${ATTESTOR_ID}.key
gpg --armor --export ${ATTESTOR_EMAIL} > /tmp/${ATTESTOR_ID}-pub.pgp

gcloud --project=${ATTESTOR_PROJECT_ID} \
  beta container binauthz attestors create ${ATTESTOR_ID} \
  --attestation-authority-note=${NOTE_ID} \
  --attestation-authority-note-project=${ATTESTOR_PROJECT_ID}

gcloud beta container binauthz attestors set-iam-policy \
  "projects/${ATTESTOR_PROJECT_ID}/attestors/${ATTESTOR_ID}" \
  --member="serviceAccount:${DEPLOYER_SERVICE_ACCOUNT}" \
  --role=roles/binaryauthorization.attestorsVerifier

gcloud --project=${ATTESTOR_PROJECT_ID} \
  beta container binauthz attestors public-keys add \
  --attestor=${ATTESTOR_ID} \
  --public-key-file=/tmp/$ATTESTOR_ID-pub.pgp
