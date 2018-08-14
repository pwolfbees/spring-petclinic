#!/bin/bash

cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)

. configuration

# remove all tmp files created during setup
echo "Removing all temporary files created by setup"
rm /tmp/$ATTESTOR_ID.key \
  /tmp/$ATTESTOR_ID-pub.pgp \
  /tmp/iam_request.json \
  /tmp/note_payload.json \
  /tmp/cloudbees-secret.json \
  /tmp/verifier_iam_policy.json

# remove gpg keys for attestor
echo "Removing GPG key created by setup for demonstration"
while 
  FINGERPRINT="$(gpg --with-colons --fingerprint $ATTESTOR_EMAIL | awk -F: '$1 == "fpr" {print $10;exit}')"
  gpg --delete-secret-keys --yes --batch "${FINGERPRINT}"
  gpg --delete-key --batch "${FINGERPRINT}"
do :;
done

