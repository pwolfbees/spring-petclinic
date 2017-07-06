pipeline {
    agent any
    environment {
        numToKeepStr = "${binding.hasVariable('CHANGE_ID') ? 3 : 100}"
        artifactNumToKeepStr = "${binding.hasVariable('CHANGE_ID') ? 1 : 5}"
    }
    
    options {
        // global timeout to kill rogue builds
        timeout(time: 12, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: "${numToKeepStr}", artifactNumToKeepStr: "${artifactNumToKeepStr}"))
        timestamps()
        skipStagesAfterUnstable()
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

