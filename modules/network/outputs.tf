##############################################
modules/network/outputs.tf
##############################################


output "vpc_id" {
  description = "ID of the VPC"
  value       = google_compute_network.galaxy_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = google_compute_subnetwork.outer_rim_subnets[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = google_compute_subnetwork.core_worlds_subnets[*].id
}

output "dns_zone_id" {
  description = "ID of the DNS zone"
  value       = google_dns_managed_zone.private_zone.id
}

output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = google_dns_managed_zone.private_zone.name
}

