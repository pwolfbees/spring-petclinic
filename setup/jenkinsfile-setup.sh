#!/bin/bash

set -e
cd $(cd -P -- "$(dirname -- "$0")" && pwd -P)

. configuration

echo "Generating Jenkinsfile"
sed "s#REPLACE_ATTESTOR_PROJECT_ID#$ATTESTOR_PROJECT_ID#; \
s#REPLACE_DEPLOYER_PROJECT_ID#${DEPLOYER_PROJECT_ID}#; \
s#REPLACE_DEPLOYER_CLUSTER#${DEPLOYER_CLUSTER}#; \
s#REPLACE_ATTESTOR_ID#${ATTESTOR_ID}#; \
s#REPLACE_ATTESTOR_EMAIL#${ATTESTOR_EMAIL}# \
s#REPLACE_DEPLOYER_CLUSTER_ZONE#${DEPLOYER_CLUSTER_ZONE}#" \
Jenkinsfile.template > ../Jenkinsfile