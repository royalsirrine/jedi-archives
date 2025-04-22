##############################################
#modules/secret_manager/outputs.tf
##############################################


output "windows_credentials_secret_id" {
  description = "ID of the Windows credentials secret"
  value       = google_secret_manager_secret.windows_credentials.id
}

output "linux_credentials_secret_id" {
  description = "ID of the Linux credentials secret"
  value       = google_secret_manager_secret.linux_credentials.id
}

output "database_credentials_secret_id" {
  description = "ID of the database credentials secret"
  value       = google_secret_manager_secret.database_credentials.id
}

output "mid_server_service_account" {
  description = "Service account for the MID Server"
  value       = google_service_account.mid_server_sa.email
}

