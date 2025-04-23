
##############################################
# modules/network/main.tf - Network Configuration
##############################################

resource "google_compute_network" "galaxy_vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  project                 = var.project_id
}

# Create a proxy-only subnet required for the regional HTTP load balancer
resource "google_compute_subnetwork" "proxy_subnet" {
  name          = "proxy-only-subnet"
  ip_cidr_range = "10.0.5.0/24"  # Use a CIDR range that doesn't conflict with your other subnets
  region        = var.region
  network       = google_compute_network.galaxy_vpc.id
  purpose       = "REGIONAL_MANAGED_PROXY"
  role          = "ACTIVE"
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

# MID Server Load Balancer Configuration
# Regional Health Check for MID Servers
resource "google_compute_region_health_check" "mid_server_health_check" {
  name               = "rebel-fleet-health-check"
  description        = "Health check for MID Server fleet"
  region             = var.region
  timeout_sec        = 5
  check_interval_sec = 10
  healthy_threshold  = 2
  unhealthy_threshold = 3
  
  tcp_health_check {
    port = "8085" # MID Server health check port
  }
}

# Backend Service for MID Servers
resource "google_compute_region_backend_service" "mid_server_backend" {
  name                  = "rebel-fleet-backend"
  description           = "Backend service for MID Server fleet"
  region                = var.region
  health_checks         = [google_compute_region_health_check.mid_server_health_check.id]
  protocol              = "TCP"
  load_balancing_scheme = "EXTERNAL"

  # Include backend from zone A
  backend {
    group = var.mid_server_instance_group_a
    balancing_mode = "CONNECTION"  # Changed from UTILIZATION to CONNECTION
  }
  
  # Include backend from zone B
  backend {
    group = var.mid_server_instance_group_b
    balancing_mode = "CONNECTION"  # Changed from UTILIZATION to CONNECTION
  }
}


# URL Map for MID Server Traffic
resource "google_compute_region_url_map" "mid_server_url_map" {
  name = "rebel-fleet-url-map"
  description = "URL map for MID Server fleet"
  region      = var.region
  default_service = google_compute_region_backend_service.mid_server_backend.id
}

# HTTP Proxy for MID Server Traffic
resource "google_compute_region_target_http_proxy" "mid_server_proxy" {
  name = "rebel-fleet-proxy"
  description = "Proxy for MID Server fleet"
  region      = var.region
  url_map = google_compute_region_url_map.mid_server_url_map.id
}

# Forwarding Rule (External IP and Ports)
resource "google_compute_forwarding_rule" "mid_server_lb" {
  name                  = "rebel-fleet-lb"
  description           = "Load balancer for MID Server fleet"
  region                = var.region
  load_balancing_scheme = "EXTERNAL"  # Changed from EXTERNAL_MANAGED
  port_range            = "80"        # Simplified to just use port 80
  backend_service       = google_compute_region_backend_service.mid_server_backend.id
  network_tier          = "PREMIUM"
  
  depends_on = [google_compute_subnetwork.proxy_subnet]
}
