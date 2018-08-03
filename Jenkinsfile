pipeline {
  agent {
    label 'maven && kaniko'
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
                    /kaniko/executor --help
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