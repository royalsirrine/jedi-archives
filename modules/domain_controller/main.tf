##############################################
#modules/domain_controller/main.tf
##############################################


# Domain Controller (Empire Strikes Back)
resource "google_compute_instance" "empire_strikes_back_dc" {
  name         = "empire-strikes-back-dc"
  machine_type = "e2-medium"  # Domain controller needs more resources
  zone         = "${var.region}-a"
  
  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2019"
      size  = 50
    }
  }
  
  network_interface {
    subnetwork = var.private_subnet_id
  }
  
  tags = var.firewall_tags
  
  metadata = {
    windows-startup-script-ps1 = <<-EOT
      # Set Administrator password
      $admin = [adsi]("WinNT://./administrator, user")
      $admin.psbase.invoke("SetPassword", "Emp1reP@ss123!")
      
      # Install AD DS role
      Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
      
      # Configure new domain - will reboot the server
      Install-ADDSForest -DomainName "starwars.local" -DomainNetbiosName "STARWARS" -InstallDns:$true -Force:$true -SafeModeAdministratorPassword (ConvertTo-SecureString "Emp1reP@ss123!" -AsPlainText -Force)
      
      # Create scheduled task to run after reboot to setup users
      $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\post-setup.ps1"'
      $trigger = New-ScheduledTaskTrigger -AtStartup
      Register-ScheduledTask -TaskName "Post-AD-Setup" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest
      
      # Create post-setup script
      @'
      # Create standard users
      New-ADUser -Name "Luke Skywalker" -GivenName "Luke" -Surname "Skywalker" -SamAccountName "luke-skywalker" -UserPrincipalName "luke-skywalker@starwars.local" -AccountPassword (ConvertTo-SecureString "RebelP@ss123!" -AsPlainText -Force) -Enabled $true
      
      New-ADUser -Name "Leia Organa" -GivenName "Leia" -Surname "Organa" -SamAccountName "leia-organa" -UserPrincipalName "leia-organa@starwars.local" -AccountPassword (ConvertTo-SecureString "RebelP@ss123!" -AsPlainText -Force) -Enabled $true
      
      New-ADUser -Name "Han Solo" -GivenName "Han" -Surname "Solo" -SamAccountName "han-solo" -UserPrincipalName "han-solo@starwars.local" -AccountPassword (ConvertTo-SecureString "RebelP@ss123!" -AsPlainText -Force) -Enabled $true
      
      # Create admin user
      New-ADUser -Name "Darth Vader" -GivenName "Darth" -Surname "Vader" -SamAccountName "darth-vader" -UserPrincipalName "darth-vader@starwars.local" -AccountPassword (ConvertTo-SecureString "Emp1reP@ss123!" -AsPlainText -Force) -Enabled $true
      
      Add-ADGroupMember -Identity "Domain Admins" -Members "darth-vader"
      
      # Remove the scheduled task so it doesn't run again
      Unregister-ScheduledTask -TaskName "Post-AD-Setup" -Confirm:$false
      '@ | Out-File C:\post-setup.ps1
      
      # Enable RDP
      Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    EOT
  }
  
  service_account {
    email  = "empire-osconfig-sa@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

