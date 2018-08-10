#!/bin/sh
set -e

# args
# 1 path to service account that has access to deploy
# 2 K8s cluster to deploy app 
# 3 GCP Project that contains K8s cluster
# 4 Full image url and tag of container to deploy
# 5 Namespace on K8s cluster to use

if [ $# -ne 5 ];
    then echo "Usage: deploy-app.sh <path to service acct key> <path to attestor private key> <attestor name> <attestor email> <attestation project> <image:tag>"
    exit 1
fi

# authenticate service accout with required permissions to sign attestation
./gcloud-credentials.sh $1 
# configure and apply the proper context for kubectl
gcloud container clusters get-credentials $2 --zone us-east1-b --project $3 --no-user-output-enabled
# update the deployment yaml with the image to be deployed
sed -i.bak "s#REPLACEME#$4#" ./k8s/deploy/petclinic-app-deploy.yaml  
# make sure the namepsace exists and create it if doesn't
kubectl get ns $5 || kubectl create ns $5
# deploy the load balancer for the application
kubectl --namespace=$5 apply -f k8s/deploy/petclinic-service-deploy.yaml 
# deploy the application
kubectl --namespace=$5 apply -f k8s/deploy/petclinic-app-deploy.yaml  