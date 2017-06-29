stage("checkout") {
  node {
    def foo = checkout scm
    foo.collect{k,v -> evaluate("env.$k = $v") }
    echo "${GIT_COMMIT}"
  }
}
