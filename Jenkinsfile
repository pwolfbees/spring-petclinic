pipeline {
    agent any
    environment {
        changeId = "${env.getProperty(BRANCH_NAME) ? 0}"
        //numToKeepStr = "${CHANGE_ID != 0 ? 3 : 100}"
        //artifactNumToKeepStr = "${CHANGE_ID != 0 ? 1 : 5}"
    }
    
    stages {
        stage("hello") {
            steps {
                echo "$changeId"
            }
        }
    }
}
