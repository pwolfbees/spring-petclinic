pipeline {
    agent any
    environment {
        numToKeepStr = "${binding.hasVariable('CHANGE_ID') ? 3 : 100}"
        artifactNumToKeepStr = "${binding.hasVariable('CHANGE_ID') ? 1 : 5}"
    }
    
    stages {
        stage("hello") {
            steps {
                echo "$numToKeepStr"
                echo "$artifactNumToKeepStr"
            }
        }
    }
}

