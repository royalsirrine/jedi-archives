##############################################
modules/firewall_rules/main.tf
##############################################


# Firewall Rules for Windows Servers (Imperial)
resource "google_compute_firewall" "imperial_security" {
  name    = "imperial-security"
  network = var.vpc_id
  
  allow {
    protocol = "tcp"
    ports    = ["3389", "5985-5986", "80", "443", "135", "445", "1024-65535"]
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["imperial-security"]
}

# Firewall Rules for Linux Servers (Rebel)
resource "google_compute_firewall" "rebel_security" {
  name    = "rebel-security"
  network = var.vpc_id
  
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "5432"]  # Added PostgreSQL port
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["rebel-security"]
}

# Firewall Rules for MID Server (Mandalorian)
resource "google_compute_firewall" "mandalorian_security" {
  name    = "mandalorian-security"
  network = var.vpc_id
  
  allow {
    protocol = "tcp"
    ports    = ["22", "3389", "8085"]  # Added MID Server port
  }
  
  allow {
    protocol = "icmp"
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["mandalorian-security"]
}

# Allow internal traffic for domain services
resource "google_compute_firewall" "internal_domain" {
  name    = "internal-domain-traffic"
  network = var.vpc_id
  
  allow {
    protocol = "tcp"
    ports    = ["53", "88", "389", "445", "636", "3268", "3269", "49152-65535"]
  }
  
  allow {
    protocol = "udp"
    ports    = ["53", "88", "123", "389", "445"]
  }
  
  source_ranges = ["10.0.0.0/16"]  # Allow from anywhere in the VPC
}

