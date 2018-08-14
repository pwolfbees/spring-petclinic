pipeline {
  agent {
    kubernetes {
        label 'petclinic'
        yaml ''' 
        apiVersion: v1
kind: Pod
metadata:
  name: kaniko-build-pod
spec:
  containers:
  - name: maven
    image: maven:3.5.0
    command:
    - cat
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    env:
      - name: GOOGLE_APPLICATION_CREDENTIALS
        value: /secret/cloudbees-secret.json
    volumeMounts:
      - name: cloudbees-secret
        mountPath: /secret
  restartPolicy: Never
  volumes:
    - name: cloudbees-secret
      secret:
        secretName: cloudbees-secret
        '''
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
          /kaniko/executor -f `pwd`/Dockerfile -c `pwd` -d ${IMAGE_URL}:${GIT_COMMIT}
          '''
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
