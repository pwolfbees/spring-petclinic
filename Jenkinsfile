pipeline {
    agent any
    environment {
        numToKeepStr = "${CHANGE_ID != null ? 3 : 100}"
        artifactNumToKeepStr = "${CHANGE_ID != null ? 1 : 5}"
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
