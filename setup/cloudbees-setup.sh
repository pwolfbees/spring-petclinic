#!/bin/sh

set -e

# This script will create the appropriate secrets needed for the Jenkins Kubernetes plugin.
# https://github.com/jenkinsci/kubernetes-plugin

. configuration

# Create service account. This service account will be used to push images to GCR and deploy the application
echo "Creating cloudbees-svc-account in GCP Project: ${CLOUDBEES_PROJECT_ID}"
gcloud iam service-accounts create cloudbees-svc-acct \
  --display-name "CloudBees Service Account"

# Name of the service account just created
SERVICE_ACCOUNT="cloudbees-svc-acct@$CLOUDBEES_PROJECT_ID.iam.gserviceaccount.com"

# Enable Service Account to push containers to GCR on the GCP Deploy Project
echo "Enabling Service Account to push containers to GCR on your behalf"
gcloud projects add-iam-policy-binding $DEPLOY_PROJECT_ID \
  --member serviceAccount:$SERVICE_ACCOUNT --role roles/storage.objectCreator

# Download a local json key file for use with service account. This key will be used to create a secret on 
# Kubernetes cluster and deleted when setup is done.
echo "Creating local json file for ${SERVICE_ACCOUNT} to be used in K8s secret"
gcloud iam service-accounts keys create /tmp/cloudbees-svc-acct.json \
  --iam-account ${SERVICE_ACCOUNT}

# If the private key for Attestor is not already present from attestor-setup then export it again.
if [ ! -f /tmp/$ATTESTOR_ID.key ]; then
  gpg --export-secret-key -a $ATTESTOR_NAME > /tmp/$ATTESTOR_ID.key
fi

# Set context for kubectl to the cluster and project where the Jenkins Pipeline will run
echo "Setting context for kubectl to ${CLOUDBEES_CLUSTER} to create Kubernetes secrets"
gcloud container clusters get-credentials $CLOUDBEES_CLUSTER \
  --project $CLOUDBEES_PROJECT_ID --no-user-output-enabled

# Add Kubernetes secrets that contain the service account id and private signing key that can be used from Jenkins Pipeline
echo "Creating Kubernetes secrets for Service Account and Attestor"
kubectl create secret generic cloudbees-svc-acct-secret --from-file=/tmp/cloudbees-svc-acct.json -n $CLOUDBEES_NAMESPACE
kubectl create secret generic attestor-secret --from-file=/tmp/$ATTESTOR_ID.key

