stage("checkout") {
  node {
    def foo = checkout scm
    def bar = foo.collect{k,v -> "env.$k = $v" }
    echo "${bar}"
  }
}
