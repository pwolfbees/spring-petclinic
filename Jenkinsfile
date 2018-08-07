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
      GOOGLE_APPLICATION_CREDENTIALS = "/secret/jenkins-secret.json"
      GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //workaround for bug in Kubernetes Plugin JENKINS-52885
      GCR_PROJECT = "cloudbees-public"
      IMAGE_PREFIX = "bin-auth"
      IMAGE_NAME = "petclinic"
      IMAGE_URL = "gcr.io/$GCR_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME"
      TARGET_PROJECT = "cloudbees-public"
      TARGET_CLUSTER = "bin-auth-deploy"
  }

  stages {
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn clean install'
        }
      }
    }
    stage('Branch Image') {
      when {
        not {
          buildingTag()
        }
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE_URL}:${GIT_COMMIT}
          '''
        } 
      }
    }
    stage('Production Image') {
      when {
          buildingTag()
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE_URL}:${GIT_COMMIT} --destination=${IMAGE_URL}:${TAG_NAME} --destination=${IMAGE_URL}:latest
          '''
        }
      }
      post {
        success {
          echo "sign it"
        }
      }
    }
    stage('Create Kubeconfig') {
      steps {
        container('gcloud') {
          sh '''
          gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS} --no-user-output-enabled
          gcloud container clusters get-credentials ${TARGET_CLUSTER} --zone us-east1-b --project ${TARGET_PROJECT} --no-user-output-enabled
          '''
        }
      }
    } 
    stage('Deploy Petclinic') {
      steps {
        container('kubectl') {
          sh '''
          sed -i.bak "s#REPLACEME#${IMAGE_URL}:${GIT_COMMIT}#" ./k8s/petclinic-deploy.yaml
          kubectl get ns ${BRANCH_NAME} || kubectl create ns ${BRANCH_NAME}
          kubectl --namespace=${BRANCH_NAME} apply -f k8s/lb-service.yaml
          kubectl --namespace=${BRANCH_NAME} apply -f k8s/petclinic-deploy.yaml
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