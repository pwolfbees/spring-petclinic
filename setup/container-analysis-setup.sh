#!/bin/sh
set -e

# args
# 1 Deployer Project ID
# 2 Attestor Project ID (may be same as Deployer)
# 3 (Optional) Name of the note to be used


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

cat /tmp/note_payload.json

curl -X POST \
 -H "Content-Type: application/json" \
 -H "Authorization: Bearer $(gcloud auth print-access-token)"  \
 --data-binary @/tmp/note_payload.json  \
"https://containeranalysis.googleapis.com/v1beta1/projects/${ATTESTOR_PROJECT_ID}/notes/?noteId=${NOTE_ID}"

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

cat /tmp/iam_request.json

echo "Updating IAM policy on ${NOTE_ID} to allow ${DEPLOYER_SERVICE_ACCOUNT} and ${ATTESTOR_SERVICE_ACCOUNT} access"
curl -X POST  \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  --data-binary @/tmp/iam_request.json \
  "https://containeranalysis.googleapis.com/v1alpha1/projects/${ATTESTOR_PROJECT_ID}/notes/${NOTE_ID}:setIamPolicy"