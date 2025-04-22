##############################################
#modules/firewall_rules/outputs.tf
##############################################


output "firewall_tags" {
  description = "Network tags for firewall rules"
  value = {
    "imperial_security"    = "imperial-security"
    "rebel_security"       = "rebel-security"
    "mandalorian_security" = "mandalorian-security"
  }
}

