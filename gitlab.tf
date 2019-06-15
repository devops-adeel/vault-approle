resource "google_service_account" "gitlab_gcs" {
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
}

resource "google_project_iam_member" "gitlab_gcs" {
  role   = "roles/storage.admin"
  member = "${google_service_account.gitlab_gcs.email}"
}

resource "google_storage_bucket" "gitlab_backups" {
  name          = "backups"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_uploads" {
  name          = "uploads"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_artifacts" {
  name          = "artifacts"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_lfs" {
  name          = "lfs"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_packages" {
  name          = "packages"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket" "gitlab_registry" {
  name          = "registry"
  location      = "EU"
  force_destroy = true
}

resource "google_compute_address" "gitlab" {
  name        = "gitlab"
  description = "Gitlab Ingress IP"
}

resource "google_compute_global_address" "gitlab_sql" {
  provider      = "google-beta"
  name          = "gitlab-sql"
  description   = "Gitlab Cloud SQL range"
  prefix_length = 20
  address_type  = "internal"
  purpose       = "VPC_PEERING"
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = "google-beta"
  network                 = "${data.google_compute_network.name}"
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = ["${google_compute_global_address.gitlab_sql.name}"]
}

resource "google_sql_database_instance" "gitlab_db" {
  provider         = "google-beta"
  name             = "gitlab-db"
  region           = "${var.region}"
  database_version = "POSTGRES_9_6"

  depends_on = [
    "google_service_networking_connection.private_vpc_connection"
  ]

  settings {
    tier            = "db-n1-standard-4"
    disk_autoresize = true
    ip_configuration {
      ipv4_enabled    = "false"
      private_network = "${data.google_compute_network.default.self_link}"
    }
  }
}

resource "random_id" "password" {
  byte_length = 4
}

resource "google_sql_user" "users" {
  name     = "gitlab"
  instance = "${google_sql_database_instance.gitlab_db.name}"
  password = "${random_id.password.hex}"
}

resource "google_sql_database" "gitlab_db" {
  name     = "gitlabhq_production"
  instance = "${google_sql_database_instance.gitlab_db.name}"
}

resource "google_redis_instance" "gitlab" {
  name           = "gitlab"
  memory_size_gb = 2
  tier           = "STANDARD_HA"
}

resource "kubernetes_namespace" "gitlab" {
  metadata {
    name = "gitlab"
  }
}

data "helm_repository" "gitlab" {
  name = "gitlab"
  url  = "https://charts.gitlab.io/"
}

resource "helm_release" "gitlab" {
  name       = "gitlab"
  repository = "${data.helm_repository.gitlab.metadata.0.name}"
  chart      = "gitlab/gitlab"
  version    = "1.7.1"
  namespace  = "gitlab"

  values = [
    "${path.module}/gitlab/${file("values.yaml")}"
  ]

  set {
    name  = "global.hosts.domain"
    value = "${google_compute_address.gitlab.address}.xip.io"
  }

  set {
    name  = "global.hosts.externalIP"
    value = "${google_compute_address.gitlab.address}"
  }

  set {
    name  = "global.psql.host"
    value = "${google_sql_database_instance.gitlab_db.ip_address.0.ip_address}"
  }

  set {
    name  = "global.redis.host"
    value = "${google_sql_database_instance.gitlab_db.ip_address.0.ip_address}"
  }

  set {
    name  = "global.appConfig.backups.bucket"
    value = "${var.project_id}-gitlab-backups"
  }

  set {
    name  = "global.appConfig.lfs.bucket"
    value = "${var.project_id}-git-lfs"
  }

  set {
    name  = "global.appConfig.artifacts.bucket"
    value = "${var.project_id}-gitlab-artifacts"
  }

  set {
    name  = "global.appConfig.uploads.bucket"
    value = "${var.project_id}-gitlab-uploads"
  }

  set {
    name  = "global.appConfig.packages.bucket"
    value = "${var.project_id}-gitlab-packages"
  }

  set {
    name  = "global.appConfig.pseudonymizer.bucket"
    value = "${var.project_id}-gitlab-pseudo"
  }

  set {
    name  = "certmanager-issuer.email"
    value = "${var.email}"
  }

  set {
    name  = "gitlab-runner.runners.cache.gcsBucketname"
    value = "${var.project_id}-runner-cache"
  }
}
