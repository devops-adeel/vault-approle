resource "kubernetes_namespace" "artifactory" {
  metadata {
    name = "artifactory"
  }
}

data "helm_repository" "artifactory" {
  name = "jfrog"
  url  = "https://charts.jfrog.io"
}

resource "helm_release" "artifactory" {
  name       = "artifactory"
  repository = "${helm_repository.artifactory.metadata.0.name}"
  chart      = "jfrog/artifactory"

  set {
    name  = "artifactory.image.repository"
    value = "docker.bintray.io/jfrog/artifactory-oss"
  }
}
