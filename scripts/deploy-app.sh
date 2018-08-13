#!/bin/sh
set -e

if [ $# -ne 5 ];
    then echo "Usage: deploy-app.sh <path to service acct key> <path to attestor private key> <attestor name> <attestor email> <attestation project> <image:tag>"
    exit 1
fi

# args
# 1 path to service account that has access to deploy 
CLOUDBEES_SVC_ACCT=$1
# 2 name of the cluster where the application will be deployed 
TARGET_CLUSTER=$2
# 3 name of the GCP project where the applicaiton will be deployed 
TARGET_PROJECT=$3
# Full Name and tag of the Container Image to be deployed
DEPLOY_IMAGE=$4
# 5 Namespace of the Target Cluster to deploy application to
NAMESPACE=$5

# authenticate service accout with required permissions to sign attestation
./gcloud-credentials.sh $CLOUDBEES_SVC_ACCT
# configure and apply the proper context for kubectl
gcloud container clusters get-credentials $TARGET_CLUSTER  --project $TARGET_PROJECT --no-user-output-enabled
# update the deployment yaml with the image to be deployed
sed -i.bak "s#REPLACEME#$DEPLOY_IMAGE#" ./k8s/deploy/petclinic-app-deploy.yaml  
# make sure the namepsace exists and create it if doesn't
kubectl get ns $NAMESPACE || kubectl create ns $NAMESPACE
# deploy the load balancer for the application
kubectl --namespace=$NAMESPACE apply -f k8s/deploy/petclinic-service-deploy.yaml 
# deploy the application
kubectl --namespace=$NAMESPACE apply -f k8s/deploy/petclinic-app-deploy.yaml  