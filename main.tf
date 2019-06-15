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

provider "kubernetes" {}
