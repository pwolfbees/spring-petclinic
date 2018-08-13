#!/bin/bash

set -e
cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)
.configuration

# remove all tmp files created during setup
echo "Removing all temporary files created by setup"
rm /tmp/$ATTESTOR_ID.key \
  /tmp/$ATTESTOR_ID-pub.pgp \
  /tmp/iam_request.json \
  /tmp/note_payload.json \
  /tmp/cloudbees-svc-acct.json \
  /tmp/verifier_iam_policy.json

# remove gpg keys for attestor
echo "Removing GPG key created by setup for demonstration"
gpg --delete-secret-key "${ATTESTOR_NAME}" 
gpg --delete-key "${ATTESTOR_NAME}"

