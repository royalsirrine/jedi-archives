##############################################
modules/network/variables.tf
##############################################

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
}

variable "network_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "region" {
  description = "GCP region to use"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "domain_controller_ip" {
  description = "IP address of the domain controller"
  type        = string
  default     = "10.0.3.10" # Default value before it's known
}

variable "mid_server_instance_group_a" {
  description = "Instance group ID for MID servers in zone A"
  type        = string
  default     = "" # This will be populated from the compute_instances module
}

variable "mid_server_instance_group_b" {
  description = "Instance group ID for MID servers in zone B"
  type        = string
  default     = "" # This will be populated from the compute_instances module
}

