##############################################
#modules/secret_manager/main.tf
##############################################


# Secret Manager for storing discovery credentials
resource "google_secret_manager_secret" "windows_credentials" {
  secret_id = "${var.environment}-windows-discovery-credentials"
  
  replication {
  user_managed {
    replicas {
      location = "us-central1"
    }
  }
}

resource "google_secret_manager_secret_version" "windows_credentials" {
  secret      = google_secret_manager_secret.windows_credentials.id
  secret_data = jsonencode({
    local_admin_username  = "empire-discovery-admin",
    local_admin_password  = "Emp1reD1sc0v3ryP@ss!",
    domain_admin_username = "darth-vader",
    domain_admin_password = "Emp1reP@ss123!"
  })
}

resource "google_secret_manager_secret" "linux_credentials" {
  secret_id = "${var.environment}-linux-discovery-credentials"
  
  replication {
  user_managed {
    replicas {
      location = "us-central1"
    }
  }
}

resource "google_secret_manager_secret_version" "linux_credentials" {
  secret      = google_secret_manager_secret.linux_credentials.id
  secret_data = jsonencode({
    username          = "rebel-discovery-user",
    password          = "R3belD1sc0v3ryP@ss!",
    ssh_key_passphrase = "R3belK3yP@ss!"
  })
}

resource "google_secret_manager_secret" "database_credentials" {
  secret_id = "${var.environment}-database-discovery-credentials"
  
  replication {
  user_managed {
    replicas {
      location = "us-central1"
    }
  }
 }
}

resource "google_secret_manager_secret_version" "database_credentials" {
  secret      = google_secret_manager_secret.database_credentials.id
  secret_data = jsonencode({
    postgresql_username = "jedi_discovery",
    postgresql_password = "J3d1D1sc0v3ryP@ss!"
  })
}

# IAM Binding for MID Server to access Secret Manager
resource "google_service_account" "mid_server_sa" {
  account_id   = "${var.environment}-mid-server-sa"
  display_name = "MID Server Service Account"
}

resource "google_project_iam_binding" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  
  members = [
    "serviceAccount:${google_service_account.mid_server_sa.email}",
  ]
}

