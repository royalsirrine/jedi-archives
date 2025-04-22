variable "project_id" {
  description = "GCP project ID"
  default     = "jedi-hackathon-project"
}

variable "region" {
  description = "GCP region to deploy resources"
  default     = "us-central1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "starwars-key"
}

variable "instance_types" {
  description = "GCP machine types to deploy"
  default = {
    "win-app01" = "e2-small" # Old Windows app server
    "win-app02" = "e2-small" # New Windows app server
    "unx-web01" = "e2-small" # Linux web server
    "unx-app01" = "e2-small" # Linux app server
    "unx-mid01" = "e2-small" # Primary MID server (Linux)
    "win-mid01" = "e2-small" # Secondary MID server (Windows)
  }
}
