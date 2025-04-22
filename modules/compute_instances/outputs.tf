##############################################
modules/compute_instances/outputs.tf
##############################################


output "instance_ids" {
  description = "IDs of the Compute Engine instances"
  value = {
    "win_app01" = google_compute_instance.win_app01.id
    "win_app02" = google_compute_instance.win_app02.id
    "unx_web01" = google_compute_instance.unx_web01.id
    "unx_app01" = google_compute_instance.unx_app01.id
    "unx_mid01" = google_compute_instance.unx_mid01.id
    "win_mid01" = google_compute_instance.win_mid01.id
  }
}

output "instance_private_ips" {
  description = "Private IPs of the Compute Engine instances"
  value = {
    "win_app01" = google_compute_instance.win_app01.network_interface[0].network_ip
    "win_app02" = google_compute_instance.win_app02.network_interface[0].network_ip
    "unx_web01" = google_compute_instance.unx_web01.network_interface[0].network_ip
    "unx_app01" = google_compute_instance.unx_app01.network_interface[0].network_ip
    "unx_mid01" = google_compute_instance.unx_mid01.network_interface[0].network_ip
    "win_mid01" = google_compute_instance.win_mid01.network_interface[0].network_ip
  }
}

output "midserver_linux_public_ip" {
  description = "Public IP of the Linux MID Server"
  value = google_compute_instance.unx_mid01.network_interface[0].access_config[0].nat_ip
}

output "midserver_windows_public_ip" {
  description = "Public IP of the Windows MID Server"
  value = google_compute_instance.win_mid01.network_interface[0].access_config[0].nat_ip
}

output "mid_server_instance_group_id" {
  description = "ID of the MID Server instance group in zone A"
  value = google_compute_instance_group.mid_server_group_a.id
}

output "mid_server_instance_group_b_id" {
  description = "ID of the MID Server instance group in zone B"
  value = google_compute_instance_group.mid_server_group_b.id
}

