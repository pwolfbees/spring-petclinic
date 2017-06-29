stage("checkout") {
  node {
    def foo = checkout scm
    foo.collect{k,v -> k = v }
    echo "${GIT_COMMIT}"
  }
}
