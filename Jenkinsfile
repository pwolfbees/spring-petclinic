pipeline {
  agent {
    kubernetes {
        label 'kaniko'
        yamlFile 'k8s/kaniko-build-pod.yaml'
    }
  }
options {
      skipDefaultCheckout true
  }
  
  environment {
      GOOGLE_APPLICATION_CREDENTIALS = "/secret/jenkins-secret.json"
      GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //workaround for bug in Kubernetes Plugin JENKINS-52885
      GCP_PROJECT = "cloudbees-public"
      IMAGE_PREFIX = "bin-auth"
      IMAGE_NAME = "petclinic"
  }

  stages {
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn clean install'
        }
      }
    }
    stage('Build Image') {
        when {
            not {
                buildingTag()
            }
        }
        steps {
            container(name:'kaniko', shell:'/busybox/sh') {
                sh '''#!/busybox/sh 
                    /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:$GIT_COMMIT
                    '''
            }
        }
    }
    stage('Build Tagged Image') {
      when {
          buildingTag()
      }
      steps {
        container(name:'kaniko', shell:'/busybox/sh') {
          sh '''#!/busybox/sh 
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --destination=gcr.io/$GCP_PROJECT/$IMAGE_PREFIX/$IMAGE_NAME:$TAG_NAME 
          '''
        }
      }
      post {
        success{
          echo "sign it"
        }
      }
    }
    stage('Set Context') {
      steps {
        container('gcloud') {
          sh "gcloud auth activate-service-account --key-file=/secret/jenkins-secret.json"
          sh "gcloud container clusters get-credentials cloudbees-core --zone us-east1-b --project cloudbees-public"
          sh "kubectl get pods"
        }
      }
    }
  }
}