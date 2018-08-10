#!/usr/bin/env groovy

def call(String file, String context, String[] destinations) {

  if (fileExists(file: "/.dockerenv")){
    command = "#!/busybox/sh  /kaniko/executor -f $file -c $context"

    for (dest in destinations) {
      command = command + " -d $dest"
    }
    sh "echo $command"
  }
  else {
    echo "Command must be run in a kaniko container"
  }
}