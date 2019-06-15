resource "google_service_account" "gitlab_gcs" {
  account_id   = "gitlab-gcs"
  display_name = "GitLab Cloud Storage"
}

resource "google_project_iam_member" "gitlab_gcs" {
  role   = "roles/storage.admin"
  member = "${google_service_account.gitlab_gcs.email}"
}

resource "google_storage_bucket" "gitlab" {
  count         = "${length(var.buckets)}"
  name          = "${element(var.buckets, (count.index))}"
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
