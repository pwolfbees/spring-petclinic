pipeline {
  agent {
    kubernetes {
        label 'petclinic'
        yamlFile 'k8s/kaniko-build-pod.yaml'
    }
  }

  options {
      skipDefaultCheckout true //workaround for bug in Kubernetes Plugin JENKINS-52885
  }
  
  environment {
    GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //workaround for bug in Kubernetes Plugin JENKINS-52885
    GOOGLE_APPLICATION_CREDENTIALS = "/secret/jenkins-secret.json"  // need K8s secret created that contains GCP service account credentials
    GCR_PROJECT = "cloudbees-public"  //name of GCP project for Kaniko to store images in GCR. Service Account must have access
    IMAGE_PREFIX = "bin-auth" //name of prefix for container images in GCR to separate from other images
    IMAGE_NAME = "petclinic" //name of image to be created
    IMAGE_URL = "gcr.io/${GCR_PROJECT}/${IMAGE_PREFIX}/${IMAGE_NAME}" //full container image URL without tag
    TARGET_PROJECT = "cloudbees-public"  //GCP Project where you want to deploy application. Requires Service Account access.
    TARGET_CLUSTER = "bin-auth-deploy"  //K8s Cluster where you want to deploy application. Requires Service Account access.
    ATTESTOR = "demo-attestor"
    ATTESTOR_EMAIL = "dattestor@example.com"
    NAMESPACE = "${TAG_NAME ? 'production' : BRANCH_NAME}"
  }

  stages {
    stage('Configure kubectl') {
      steps {
        container('gcloud') {
          sh '''
          gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --no-user-output-enabled
          gcloud container clusters get-credentials ${TARGET_CLUSTER} --zone us-east1-b --project ${TARGET_PROJECT} --no-user-output-enabled
          '''
        }
      }
    }
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn clean install -DskipTests=true'
        }
      }
    }
    stage('Create Branch Image') {
      when {
        not {
          buildingTag()
        }
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE_URL}:${GIT_COMMIT}
          sed -i.bak "s#REPLACEME#${IMAGE_URL}:${GIT_COMMIT}#" ./k8s/petclinic-deploy.yaml
          '''
        } 
      }
    }
    stage('Create Production Image') {
      when {
          buildingTag()
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE_URL}:${GIT_COMMIT} --destination=${IMAGE_URL}:${TAG_NAME} --destination=${IMAGE_URL}:latest
          sed -i.bak "s#REPLACEME#${IMAGE_URL}:${TAG_NAME}#" ./k8s/petclinic-deploy.yaml
          '''
        }
      }
    }
    stage('Attest Tagged Image') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          sh '''
          ARTIFACT_URL="$(gcloud container images describe ${IMAGE_URL}:${GIT_COMMIT} --format='value(image_summary.fully_qualified_digest)')"
          gcloud beta container binauthz create-signature-payload --artifact-url="$ARTIFACT_URL" > /tmp/generated_payload.json
          gpg --allow-secret-key-import --import /attestor/dattestor.asc
          gpg --local-user "${ATTESTOR_EMAIL}" --armor --output /tmp/generated_signature.pgp --sign /tmp/generated_payload.json
          gcloud beta container binauthz attestations create --artifact-url="$ARTIFACT_URL" --attestor="projects/${TARGET_PROJECT}/attestors/${ATTESTOR}}" --signature-file=/tmp/generated_signature.pgp --pgp-key-fingerprint="$(gpg --with-colons --fingerprint ${ATTESTOR_EMAIL} | awk -F: '$1 == "fpr" {print $10;exit}')"
          '''
        }
      }
    } 
    stage('Deploy Petclinic') {
      steps {
        container('kubectl') {
          sh '''
          kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}
          kubectl --namespace=${NAMESPACE} apply -f k8s/lb-service.yaml
          kubectl --namespace=${NAMESPACE} apply -f k8s/petclinic-deploy.yaml
          '''
        }
      }
    }
  }
  post {
    always {
      cleanWs()
    }
  }
}