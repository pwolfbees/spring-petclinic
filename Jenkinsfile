pipeline {
  agent {
    kubernetes {
        label 'kaniko'
        yaml """
apiVersion: v1
kind: Pod
metadata:
  name: kaniko
spec:
  containers:
  - name: maven
    image: maven:3.5.0
    command:
    - cat
    tty: true
  - name: gcloud
    image: gcr.io/cloud-builders/gcloud
    command:
    - cat
    tty: true
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    command:
    - cat
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
      - name: kaniko-secret
        mountPath: /secret
    env:
      - name: GOOGLE_APPLICATION_CREDENTIALS
        value: /secret/kaniko-secret.json
  restartPolicy: Never
  volumes:
    - name: kaniko-secret
      secret:
        secretName: kaniko-secret
"""
    }
  }
options {
      skipDefaultCheckout true
  }
  
  environment {
      GIT_COMMIT = "${checkout (scm).GIT_COMMIT}"  //workaround for bug in Kubernetes Plugin JENKINS-52885
      GCP_PROJECT = "cloudbees-public"
      IMAGE_PREFIX = "bin-auth"
      IMAGE_NAME = "petclinic"
  }


  stages {
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn --version' //clean install'
        }
      }
    }
    stage('Build Image') {
        when {
            //not {
                buildingTag()
          //  }
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
          sh "gcloud container clusters get-credentials bin-auth-deploy"
        }
      }
    }
  }
}