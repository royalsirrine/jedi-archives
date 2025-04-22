##############################################
modules/domain_controller/outputs.tf
##############################################


output "domain_controller_id" {
  description = "ID of the domain controller instance"
  value       = google_compute_instance.empire_strikes_back_dc.id
}

output "domain_controller_private_ip" {
  description = "Private IP of the domain controller"
  value       = google_compute_instance.empire_strikes_back_dc.network_interface[0].network_ip
}

