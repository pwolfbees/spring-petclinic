
#!/bin/sh
gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --no-user-output-enabled
gcloud container clusters get-credentials ${TARGET_CLUSTER} --zone us-east1-b --project ${TARGET_PROJECT} --no-user-output-enabled