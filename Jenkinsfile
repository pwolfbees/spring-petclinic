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
    DEPLOYER_PROJECT_ID = "cloudbees-public"  
    DEPLOYER_CLUSTER = "bin-auth-deploy" 
    ATTESTOR = "demo-attestor"  //name of the attestor to use
    ATTESTOR_EMAIL = "dattestor@example.com"  
    
    //Static Env Variables
    GOOGLE_APPLICATION_CREDENTIALS = "/secret/cloudbees-svc-acct.json" //name of the secret file containing service account credentials
    IMAGE_PREFIX = "bin-auth" //name of prefix for container images in GCR to separate from other images
    IMAGE_NAME = "petclinic" //name of image to be created
    IMAGE_URL = "gcr.io/${DEPLOYER_PROJECT_ID}/${IMAGE_PREFIX}/${IMAGE_NAME}" //full container image URL without tag
    
    //Env Variables set by context of running pipeline
    GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //Workaround for bug in Kubernetes Plugin JENKINS-52885
    NAMESPACE = "${TAG_NAME ? 'production' : BRANCH_NAME}" //Set the k8s namespace to be either production or the branch name
    DEPLOY_IMAGE = "${IMAGE_URL}${TAG_NAME ?: GIT_COMMIT}"
  }

  stages {
    stage('Maven') {
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
          echo $ENV 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` -d ${IMAGE_URL}:${GIT_COMMIT}
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
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` -d ${IMAGE_URL}:${GIT_COMMIT} -d ${IMAGE_URL}:latest -d ${IMAGE_URL}:${TAG_NAME}
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
          sh "./scripts/sign-attestation.sh ${GOOGLE_APPLICATION_CREDENTIALS} '/attestor/dattestor.asc' ${ATTESTOR} ${ATTESTOR_EMAIL} ${ATTESTOR_PROJECT_ID} ${DEPLOY_CONTAINER}"
        }
      }
    } 
    stage('Deploy Petclinic') {
      steps {
        container('gcloud') {
          sh "./scripts/deploy-app.sh ${GOOGLE_APPLICATION_CREDENTIALS} ${TARGET_CLUSTER} ${DEPLOYER_PROJECT_ID} ${DEPLOY_IMAGE} ${NAMESPACE}"
        }
      }
    }
  }
  post {
    always {
      deleteDir()
    }
  }
}
