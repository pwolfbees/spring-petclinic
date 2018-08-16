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
    ATTESTOR_PROJECT_ID = "cloudbees-public"
    DEPLOYER_PROJECT_ID = "cje-marketplace_dev"  
    DEPLOYER_CLUSTER = "bin-auth-deploy" 
    DEPLOYER_CLUSTER_ZONE="us-central1-a"
    ATTESTOR = "build-attestor"  //name of the attestor to use
    ATTESTOR_EMAIL = "buildattestor@example.com"
    ATTESTOR_KEY = "/attestor/${ATTESTOR}.key"
    DEPLOYER_PRODUCTION_NAMESPACE = "production" 
    
    PROD_ATTEST_KEY="/prodattest/prodattest.key"
    PROD_ATTESTOR="prod-attestor"
    PROD_ATTEST_EMAIL="prodattestor@example.com"

    //Static Env Variables
    GOOGLE_APPLICATION_CREDENTIALS = "/secret/cloudbees-secret.json" //name of the secret file containing service account credentials
    IMAGE_PREFIX = "bin-auth" //name of prefix for container images in GCR to separate from other images
    IMAGE_NAME = "petclinic" //name of image to be created
    IMAGE_URL = "gcr.io/${DEPLOYER_PROJECT_ID}/${IMAGE_PREFIX}/${IMAGE_NAME}" //full container image URL without tag
    
    //Env Variables set by context of running pipeline
    //Workaround for bug in Kubernetes Plugin JENKINS-52885
    GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  
    //Set the k8s namespace to be either production or the branch name
    NAMESPACE = "${TAG_NAME ? DEPLOYER_PRODUCTION_NAMESPACE : BRANCH_NAME}" 
    DEPLOY_IMAGE = "${IMAGE_URL}:${GIT_COMMIT}"

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
    stage('Create Branch Image') {
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
        not {
          buildingTag()
        }
      }
      steps {
        container('gcloud') {
          sh "./scripts/sign-attestation.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${ATTESTOR_KEY} ${ATTESTOR} ${ATTESTOR_EMAIL} ${ATTESTOR_PROJECT_ID} ${DEPLOY_IMAGE}"
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
    stage('Attest Tag Image') {
      when {
          buildingTag()
      }
      steps {
        container('gcloud') {
          sh "./scripts/sign-attestation.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${PROD_ATTEST_KEY} ${PROD_ATTESTOR} ${PROD_ATTEST_EMAIL} ${ATTESTOR_PROJECT_ID} ${DEPLOY_IMAGE}"
        }
      }
    } 
  }
}
