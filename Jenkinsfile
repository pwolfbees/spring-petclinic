pipeline {
  agent {
    kubernetes {
        label 'petclinic'
        yamlFile 'k8s/jenkins-agent/kaniko-build-pod.yaml'
    }
  }

  options {
      skipDefaultCheckout true //Workaround for bug in Kubernetes Plugin JENKINS-52885
  }
  
  environment {
    //Env Variables that must be set before first run
    GCR_PROJECT = "cloudbees-public" 
    TARGET_PROJECT = "cloudbees-public"  
    TARGET_CLUSTER = "bin-auth-deploy" 
    ATTESTOR = "demo-attestor"  //name of the attestor to use
    ATTESTOR_EMAIL = "dattestor@example.com"  //email of the attestor to use
    GOOGLE_APPLICATION_CREDENTIALS = "/secret/jenkins-secret.json" //name of the secret file containing service account credentials
    
    //Static Env Variables 
    IMAGE_PREFIX = "bin-auth" //name of prefix for container images in GCR to separate from other images
    IMAGE_NAME = "petclinic" //name of image to be created
    IMAGE_URL = "gcr.io/${GCR_PROJECT}/${IMAGE_PREFIX}/${IMAGE_NAME}" //full container image URL without tag
    
    //Env Variables set by context of running pipeline
    GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //Workaround for bug in Kubernetes Plugin JENKINS-52885
    NAMESPACE = "${TAG_NAME ? 'production' : BRANCH_NAME}" //Set the k8s namespace to be either production or the branch name
    DEPLOY_CONTAINER = "${IMAGE_URL}${TAG_NAME ?: GIT_COMMIT}"
  }

  stages {
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
          sh "./scripts/kaniko.sh `pwd`/Dockerfile `pwd` ${IMAGE_URL}:${GIT_COMMIT}"
        } 
      }
    }
    stage('Create Production Image') {
      when {
          buildingTag()
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh "./scripts/kaniko.sh `pwd`/Dockerfile `pwd` ${IMAGE_URL}:${GIT_COMMIT} ${IMAGE_URL}:latest  ${IMAGE_URL}:${TAG_NAME}"
        }
      }
    }
    stage('Attest Tagged Image') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          //sh '''
          //ARTIFACT_URL="$(gcloud container images describe ${IMAGE_URL}:${TAG_NAME} --format='value(image_summary.fully_qualified_digest)')"
          //gcloud beta container binauthz create-signature-payload --artifact-url="$ARTIFACT_URL" > /tmp/generated_payload.json
          //gpg --allow-secret-key-import --import /attestor/dattestor.asc
          //gpg --local-user "${ATTESTOR_EMAIL}" --armor --output /tmp/generated_signature.pgp --sign /tmp/generated_payload.json
          //gcloud beta container binauthz attestations create --artifact-url="$ARTIFACT_URL" --attestor="projects/${TARGET_PROJECT}/attestors/${ATTESTOR}}" --signature-file=/tmp/generated_signature.pgp --pgp-key-fingerprint="$(gpg --with-colons --fingerprint ${ATTESTOR_EMAIL} | awk -F: '$1 == "fpr" {print $10;exit}')"
          //'''
          sh '''
          ./sign-attestation.sh "${GOOGLE_APPLICATION_CREDENTIALS}" "/attestor/dattestor.asc" "${ATTESTOR}" "${ATTESTOR_EMAIL}" "${TARGET_PROJECT}" "${IMAGE_URL}:${TAG_NAME}"
          '''
        }
      }
    } 
    stage('Deploy Petclinic') {
      steps {
        container('gcloud') {
          sh '''
          gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --no-user-output-enabled
          gcloud container clusters get-credentials ${TARGET_CLUSTER} --zone us-east1-b --project ${TARGET_PROJECT} --no-user-output-enabled
          sed -i.bak "s#REPLACEME#${DEPLOY_CONTAINER}#" ./k8s/deploy/petclinic-app-deploy.yaml  
          kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}
          kubectl --namespace=${NAMESPACE} apply -f k8s/deploy/petclinic-service-deploy.yaml  
          kubectl --namespace=${NAMESPACE} apply -f k8s/deploy/petclinic-app-deploy.yaml  
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