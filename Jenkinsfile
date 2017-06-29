stage("checkout") {
  node {
    checkout(scm).each { k,v -> env.setProperty(k, v) }
    echo "$GIT_COMMIT"
  }
}
