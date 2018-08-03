pipeline {
  agent {
    label 'maven && kaniko && k8s'
  }
  stages {
    stage('Maven') {
      steps {
        container('maven') {
          sh 'mvn clean install'
        }
      }
    }
    stage('Docker Build') {
        steps {
            container(name:'kaniko-debug', shell:'/busybox/sh') {
                sh '''#!/busybox/sh 
                    /kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure-skip-tls-verify --destination=gcr.io/partner-demo-dev/bin-auth/petclinic:latest
                    '''
            }
        }
        post {
            success{
                echo "sign it"
            }
        }
    }
  }
}