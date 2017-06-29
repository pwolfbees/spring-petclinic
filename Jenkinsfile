stage("checkout") {
  node {
    checkout(scm).each { k,v -> env.set(k, v) }
    echo "$GIT_COMMIT"
  }
}
