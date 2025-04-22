##############################################
modules/compute_instances/variables.tf
##############################################



variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "firewall_tags" {
  description = "Map of firewall tags"
  type        = map(string)
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "instance_types" {
  description = "Map of machine types for different VM instances"
  type        = map(string)
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "mid_server_service_account" {
  description = "Service account email for MID Server"
  type        = string
}

variable "domain_controller_ip" {
  description = "IP address of the domain controller"
  type        = string
  default     = "10.0.3.10"
}

