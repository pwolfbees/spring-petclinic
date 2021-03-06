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
    ATTESTOR_PROJECT_ID="cloudbees-public"
    DEPLOYER_PROJECT_ID="cje-marketplace-dev"  
    DEPLOYER_PRODUCTION_NAMESPACE="production" 

    DEPLOYER_DEV_CLUSTER_NAME="dev" 
    DEPLOYER_DEV_CLUSTER_ZONE="us-central1-a"
    DEPLOYER_PROD_CLUSTER_NAME="prod" 
    DEPLOYER_PROD_CLUSTER_ZONE="us-central1-a"

    BUILD_ATTESTOR_ID="build-attestor"  //name of the attestor to use
    BUILD_ATTESTOR_EMAIL="buildattestor@example.com"
    BUILD_ATTESTOR_KEY="/buildsecret/${BUILD_ATTESTOR_ID}.key"
    
    TAG_ATTESTOR_ID="tag-attestor"  //name of the attestor to use
    TAG_ATTESTOR_EMAIL="tagattestor@example.com"
    TAG_ATTESTOR_KEY="/tagsecret/${TAG_ATTESTOR_ID}.key"
    
    //Static Env Variables
    GOOGLE_APPLICATION_CREDENTIALS = "/secret/cloudbees-secret.json" //name of the secret file containing service account credentials
    IMAGE_PREFIX="bin-auth" //name of prefix for container images in GCR to separate from other images
    IMAGE_NAME="petclinic" //name of image to be created
    IMAGE_URL="gcr.io/${DEPLOYER_PROJECT_ID}/${IMAGE_PREFIX}/${IMAGE_NAME}" //full container image URL without tag
    
    //Env Variables set by context of running pipeline
    //Workaround for bug in Kubernetes Plugin JENKINS-52885
    GIT_COMMIT="${checkout (scm).GIT_COMMIT}"  
    //Set the k8s namespace to be either production or the branch name
    NAMESPACE="${TAG_NAME ? DEPLOYER_PRODUCTION_NAMESPACE : BRANCH_NAME}" 
    DEPLOY_IMAGE="${IMAGE_URL}:${GIT_COMMIT}"
  }

  stages {
    stage('Maven') {
      when {
        not {
          buildingTag()
        }
      }
      steps {
        container('maven') {
          sh 'mvn clean install'
        }
      }
    }
    stage('Create Dev Branch Image') {
      when {
        not {
          buildingTag()
        }
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` -d ${IMAGE_URL}:${GIT_COMMIT}
          '''
        } 
      }
    }
    stage('Attest Branch Image') {
      when {
        not{
          buildingTag()
        }
      }
      steps {
        container('gcloud') {
          sh "./scripts/sign-attestation.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${BUILD_ATTESTOR_KEY} ${BUILD_ATTESTOR_ID} ${BUILD_ATTESTOR_EMAIL} ${ATTESTOR_PROJECT_ID} ${DEPLOY_IMAGE}"
        }
      }
    }  
    stage('Deploy Dev Branch') {
      when {
        not {
          buildingTag()
        }
      }
      steps {
        container('gcloud') {
          sh "./scripts/deploy-app.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${DEPLOYER_DEV_CLUSTER_NAME} ${DEPLOYER_PROJECT_ID} ${DEPLOYER_DEV_CLUSTER_ZONE} ${DEPLOY_IMAGE} ${NAMESPACE}"
        }
      }
    }
    stage('Add Tag to Image') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          sh "./scripts/add_image_tags.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${DEPLOY_IMAGE} ${IMAGE_URL} ${TAG_NAME}"
        }
      }
    }  
    stage('Attest Tagged Image') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          sh "./scripts/sign-attestation.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${TAG_ATTESTOR_KEY} ${TAG_ATTESTOR_ID} ${TAG_ATTESTOR_EMAIL} ${ATTESTOR_PROJECT_ID} ${DEPLOY_IMAGE}"
        }
      }
    } 
    stage('Deploy Release') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          sh "./scripts/deploy-app.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${DEPLOYER_PROD_CLUSTER_NAME} ${DEPLOYER_PROJECT_ID} ${DEPLOYER_PROD_CLUSTER_ZONE} ${DEPLOY_IMAGE} ${NAMESPACE}"
        }
      }
    } 
  }
}
