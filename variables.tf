variable credentials {
  description = "Google Credentials file"
  type        = "string"
}

variable project_id {
  description = "Project ID"
  type        = "string"
}

variable region {
  type        = "string"
  default     = "europe-west2"
  description = "Region in which to deploy"
}

variable zone {
  type        = "string"
  default     = "europe-west2a"
  description = "Zone in which to deploy"
}

variable buckets {
  type        = "list"
  description = "List of GCS bucket names"
  default = [
    "uploads",
    "artifacts",
    "lfs",
    "packages",
    "registry"
  ]
}
