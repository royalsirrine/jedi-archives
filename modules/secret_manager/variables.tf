##############################################
modules/secret_manager/variables.tf
##############################################


variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name for resource naming"
  type        = string
  default     = "hackathon"
}

