#!/bin/sh

.configuration

# remove all tmp files created during setup
rm /tmp/$ATTESTOR_ID.key \
  /tmp/$ATTESTOR_ID-pub.pgp \
  /tmp/iam_request.json \
  /tmp/note_payload.json \
  /tmp/cloudbees-svc-acct.json \

# remove gpg keys for attestor
gpg --delete-secret-key "${ATTESTOR_NAME}" 
gpg --delete-key "${ATTESTOR_NAME}"

