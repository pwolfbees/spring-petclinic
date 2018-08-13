#!/bin/sh
set -e


# Refer to latest Documentation for help
# https://cloud.google.com/binary-authorization/docs/creating-attestors

. configuration

echo "Setting gcloud project context to ${DEPLOYER_PROJECT_ID}"
gcloud config set project ${DEPLOYER_PROJECT_ID}
echo "Enabling required apis on project"
gcloud services enable container.googleapis.com containeranalysis.googleapis.com binaryauthorization.googleapis.com

# Get Service Accounts for Deployer Project and Attestor Project to enable binary authorization service
DEPLOYER_PROJECT_NUMBER=$(gcloud projects describe "${DEPLOYER_PROJECT_ID}" --format="value(projectNumber)")
ATTESTOR_PROJECT_NUMBER=$(gcloud projects describe "${ATTESTOR_PROJECT_ID}" --format="value(projectNumber)")
DEPLOYER_SERVICE_ACCOUNT="service-${DEPLOYER_PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"
ATTESTOR_SERVICE_ACCOUNT="service-${ATTESTOR_PROJECT_NUMBER}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

echo "Generating json for container analysis note"
cat > /tmp/note_payload.json << EOM
{
  "name": "projects/${ATTESTOR_PROJECT_ID}/notes/${NOTE_ID}",
  "attestation_authority": {
    "hint": {
      "human_readable_name": "Note for Binary Authorization Demo"
    }
  }
}
EOM

# Display the json created for this step
cat /tmp/note_payload.json

# Create Container Analysis Note using the API
echo "Creating Container Analysis Note"
curl -X POST \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
 --data-binary @/tmp/note_payload.json  \
"https://containeranalysis.googleapis.com/v1beta1/projects/${ATTESTOR_PROJECT_ID}/notes/?noteId=${NOTE_ID}"

# Validate that the note was created properly
echo "Existing container notes on Attestor Project:"
curl \
   -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
   "https://containeranalysis.googleapis.com/v1beta1/projects/${ATTESTOR_PROJECT_ID}/notes/"


echo "Generating json for iam policy for service accounts to access note"
cat > /tmp/iam_request.json << EOM
{
  "resource": "projects/${ATTESTOR_PROJECT_ID}/notes/${NOTE_ID}",
  "policy": {
    "bindings": [
      {
        "role": "roles/containeranalysis.notes.occurrences.viewer",
        "members": [
          "serviceAccount:${DEPLOYER_SERVICE_ACCOUNT}",
          "serviceAccount:${ATTESTOR_SERVICE_ACCOUNT}"
        ]
      }
    ]
  }
}
EOM

# Display the json created for this step
cat /tmp/iam_request.json

# Update the IAM policy on the note created in the last step.
echo "Updating IAM policy on ${NOTE_ID} to allow ${DEPLOYER_SERVICE_ACCOUNT} and ${ATTESTOR_SERVICE_ACCOUNT} access"
curl -X POST  \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-binary @/tmp/iam_request.json \
  "https://containeranalysis.googleapis.com/v1alpha1/projects/${ATTESTOR_PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"

echo "Setting up Attestor"

echo "Generating public and private key for attestor account $ATTESTOR_EMAIL"
gpg --batch --gen-key <(
  cat <<- EOF
    Key-Type: RSA
    Key-Length: 2048
    Name-Real: "${ATTESTOR_NAME}"
    Name-Email: "${ATTESTOR_EMAIL}"
    %commit
EOF
)

echo "Exporting private and public keys for Attestor"
gpg --export-secret-key -a ${ATTESTOR_NAME} > /tmp/${ATTESTOR_ID}.key
gpg --armor --export ${ATTESTOR_EMAIL} > /tmp/${ATTESTOR_ID}-pub.pgp

# Create Attestor in Attestor Project
echo "Creating new Attestor"
gcloud --project=${ATTESTOR_PROJECT_ID} \
  beta container binauthz attestors create ${ATTESTOR_ID} \
  --attestation-authority-note=${NOTE_ID} \
  --attestation-authority-note-project=${ATTESTOR_PROJECT_ID}

# Grant permission for Deployer Service account to verify containers
echo "Granting permission for Deployer service account to verify contiainer"
gcloud beta container binauthz attestors set-iam-policy \
  "projects/${ATTESTOR_PROJECT_ID}/attestors/${ATTESTOR_ID}" \
  --member="serviceAccount:${DEPLOYER_SERVICE_ACCOUNT}" \
  --role=roles/binaryauthorization.attestorsVerifier

# Add public key for Attestor
echo "Adding public key for Attestor"
gcloud --project=${ATTESTOR_PROJECT_ID} \
  beta container binauthz attestors public-keys add \
  --attestor=${ATTESTOR_ID} \
  --public-key-file=/tmp/$ATTESTOR_ID-pub.pgp
