resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  location   = "${var.zone}"
  cluster    = "${google_container_cluster.primary.name}"
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_container_cluster" "primary" {
  name                     = "gitlab-artifactory-vault"
  description              = "Cluster to create vault-artifactory-gitlab"
  location                 = "${var.zone}"
  remove_default_node_pool = true
  initial_node_count       = 3

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}
