##############################################
# modules/network/main.tf - Network Configuration
##############################################

resource "google_compute_network" "galaxy_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Configure Cloud DNS for internal name resolution
resource "google_dns_managed_zone" "private_zone" {
  name        = "starwars-local-zone"
  dns_name    = "starwars.local."
  description = "Private DNS zone for StarWars domain"
  project     = var.project_id

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.galaxy_vpc.id
    }
  }
}

# Add a DNS record for the domain controller
resource "google_dns_record_set" "dc_dns" {
  name         = "win-dc01.starwars.local."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_zone.name
  project      = var.project_id
  
  # This will be populated by the domain controller's IP address
  rrdatas = [var.domain_controller_ip != "" ? var.domain_controller_ip : "10.0.3.10"]
  
  depends_on = [google_dns_managed_zone.private_zone]
}

# Public Subnets
resource "google_compute_subnetwork" "outer_rim_subnets" {
  count         = length(var.public_subnet_cidrs)
  name          = "public-subnet-${count.index + 1}"
  ip_cidr_range = var.public_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.galaxy_vpc.id
  project       = var.project_id
}

# Private Subnets
resource "google_compute_subnetwork" "core_worlds_subnets" {
  count         = length(var.private_subnet_cidrs)
  name          = "private-subnet-${count.index + 1}"
  ip_cidr_range = var.private_subnet_cidrs[count.index]
  region        = var.region
  network       = google_compute_network.galaxy_vpc.id
  project       = var.project_id
}

# Cloud Router
resource "google_compute_router" "hyperspace_router" {
  name    = "hyperspace-router"
  region  = var.region
  network = google_compute_network.galaxy_vpc.id
  project = var.project_id
}

# Cloud NAT
resource "google_compute_router_nat" "lightspeed_nat" {
  name                               = "lightspeed-nat"
  router                             = google_compute_router.hyperspace_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  project                            = var.project_id

  subnetwork {
    name                    = google_compute_subnetwork.core_worlds_subnets[0].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.core_worlds_subnets[1].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}
