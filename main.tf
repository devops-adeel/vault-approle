terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "coefficient-data"

    workspaces {
      name = "vault"
    }
  }
}

provider "google" {
  credentials = "${file(var.credentials)}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

provider "google-beta" {
  credentials = "${file(var.credentials)}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

provider "kubernetes" {
  host                   = "${google_container_cluster.primary.endpoint}"
  client_certificate     = "${google_container_cluster.primary.master_auth.0.client_certificate}"
  client_key             = "${google_container_cluster.primary.master_auth.0.client_key}"
  cluster_ca_certificate = "${google_container_cluster.primary.master_auth.0.cluster_ca_certificate}"
}

provider "helm" {
  host = "${google_container_cluster.primary.endpoint}"
  home = "${var.home}"
  kubernetes {
    config_path = "/path/to/kube_cluster.yaml"
  }
}

