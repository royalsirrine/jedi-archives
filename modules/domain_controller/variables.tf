##############################################
modules/domain_controller/variables.tf
##############################################


variable "private_subnet_id" {
  description = "ID of the private subnet for the domain controller"
  type        = string
}

variable "firewall_tags" {
  description = "List of firewall tags"
  type        = list(string)
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

