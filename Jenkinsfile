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
      GCP_PROJECT = "cloudbees-public"
      IMAGE_PREFIX = "bin-auth"
      IMAGE_NAME = "petclinic"
      IMAGE_TAG = "gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:$GIT_COMMIT"
      NAMESPACE = "${env.TAG_NAME ?: env.BRANCH_NAME}"
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
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=${IMAGE_TAG}
          '''
          sh "sed -i.bak 's#gcr.io/${GCP_PROJECT}/${IMAGE_PREFIX}/${IMAGE_NAME}:REPLACEME#${IMAGE_TAG}#' ./k8s/petclinic-deploy.yaml"
        } 
      }
    }
    stage('Deploy') {
      steps {
        container('gcloud') {
          sh "gcloud auth activate-service-account --key-file=/secret/jenkins-secret.json --no-user-output-enabled"
          sh "gcloud container clusters get-credentials bin-auth-deploy --zone us-east1-b --project cloudbees-public"
          sh "kubectl get ns ${NAMESPACE} || kubectl create ns ${NAMESPACE}"
          sh "kubectl --namespace=${NAMESPACE} apply -f k8s/lb-service.yaml"
          sh "kubectl --namespace=${NAMESPACE} apply -f k8s/petclinic-deploy.yaml" 
        }
      }
    }
    stage('Production Build') {
      when {
          buildingTag()
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:$TAG_NAME --destination=gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:$GIT_COMMIT --destination=gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:latest
          '''
        }
      }
    } 
  }
}