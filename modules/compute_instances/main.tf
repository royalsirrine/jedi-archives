##############################################
#modules/compute_instances/main.tf
##############################################


# Create SSH Key Pair (if not using OS Login)

resource "tls_private_key" "starwars_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.starwars_key.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}


# Linux Web Server (unx-web01)
resource "google_compute_instance" "unx_web01" {
  name         = "unx-web01"
  machine_type = var.instance_types["unx-web01"]
  zone         = "${var.region}-b"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.private_subnet_ids[1]
  }

  tags = [var.firewall_tags["rebel_security"]]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    
    # Update packages
    apt update && apt upgrade -y
    
    # Create discovery user with sudo privileges
    useradd -m -s /bin/bash rebel-discovery-user
    echo "rebel-discovery-user:R3belD1sc0v3ryP@ss!" | chpasswd
    echo "rebel-discovery-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rebel-discovery-user
    chmod 0440 /etc/sudoers.d/rebel-discovery-user
    
    # Configure SSH for discovery
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Configure DNS resolution to use domain controller
    echo "nameserver ${var.domain_controller_ip}" > /etc/resolv.conf
    echo "search starwars.local" >> /etc/resolv.conf
    
    # Make DNS changes persistent
    echo "nameserver ${var.domain_controller_ip}" > /etc/resolv.conf.new
    echo "search starwars.local" >> /etc/resolv.conf.new
    mv /etc/resolv.conf.new /etc/resolv.conf
    
    # Install Apache
    apt install -y apache2
    systemctl start apache2
    systemctl enable apache2
    
    # Create test page
    echo "<html><body><h1>Rebel Alliance Web Portal</h1><p>Instance Type: $(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/machine-type)</p></body></html>" > /var/www/html/index.html
    
    # Create security software simulation
    mkdir -p /opt/blast-shield/bin
    mkdir -p /opt/blast-shield/conf
    echo "version=3.2.1" > /opt/blast-shield/version.txt
    echo "shield.enabled=true" > /opt/blast-shield/conf/shield.conf
  EOT

  service_account {
    email  = "empire-osconfig-sa@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

# Linux App Server (unx-app01)
resource "google_compute_instance" "unx_app01" {
  name         = "unx-app01"
  machine_type = var.instance_types["unx-app01"]
  zone         = "${var.region}-b"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
    }
  }

  network_interface {
    subnetwork = var.private_subnet_ids[1]
  }

  tags = [var.firewall_tags["rebel_security"]]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    
    # Update packages
    apt update && apt upgrade -y
    
    # Create discovery user with sudo privileges
    useradd -m -s /bin/bash rebel-discovery-user
    echo "rebel-discovery-user:R3belD1sc0v3ryP@ss!" | chpasswd
    echo "rebel-discovery-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rebel-discovery-user
    chmod 0440 /etc/sudoers.d/rebel-discovery-user
    
    # Configure SSH for discovery
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Configure DNS resolution to use domain controller
    echo "nameserver ${var.domain_controller_ip}" > /etc/resolv.conf
    echo "search starwars.local" >> /etc/resolv.conf
    
    # Make DNS changes persistent
    echo "nameserver ${var.domain_controller_ip}" > /etc/resolv.conf.new
    echo "search starwars.local" >> /etc/resolv.conf.new
    mv /etc/resolv.conf.new /etc/resolv.conf
    
    # Install Java 17
    apt install -y openjdk-17-jre-headless
    
    # Install Tomcat
    mkdir -p /opt/tomcat
    cd /tmp
    wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.74/bin/apache-tomcat-9.0.74.tar.gz
    tar xf apache-tomcat-9.0.74.tar.gz -C /opt/tomcat --strip-components=1
    
    # Set permissions
    chown -R $(whoami):$(whoami) /opt/tomcat
    chmod +x /opt/tomcat/bin/*.sh
    
    # Start Tomcat
    /opt/tomcat/bin/startup.sh
    
    # Create lightsaber application
    mkdir -p /opt/tomcat/webapps/lightsaber-app/WEB-INF
    echo "<html><body><h1>Lightsaber Training Application</h1><p>Running on Tomcat</p></body></html>" > /opt/tomcat/webapps/lightsaber-app/index.html
    
    # Install PostgreSQL database
    apt install -y postgresql postgresql-contrib
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Configure PostgreSQL for remote connections
    sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'J3d1DB@dm1n';"
    
    # Create jedi_records database and tables
    sudo -u postgres psql -c "CREATE DATABASE jedi_records;"
    sudo -u postgres psql -d jedi_records -c "
    CREATE TABLE jedi_knights (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      rank VARCHAR(50) NOT NULL,
      lightsaber_color VARCHAR(20),
      home_planet VARCHAR(50),
      midi_chlorian_count INTEGER
    );
    
    CREATE TABLE jedi_missions (
      id SERIAL PRIMARY KEY,
      mission_name VARCHAR(100) NOT NULL,
      mission_type VARCHAR(50) NOT NULL,
      start_date DATE,
      end_date DATE,
      status VARCHAR(20),
      jedi_id INTEGER REFERENCES jedi_knights(id)
    );
    "
    
    # Insert sample data
    sudo -u postgres psql -d jedi_records -c "
    INSERT INTO jedi_knights (name, rank, lightsaber_color, home_planet, midi_chlorian_count)
    VALUES
    ('Luke Skywalker', 'Jedi Master', 'Green', 'Tatooine', 14500),
    ('Obi-Wan Kenobi', 'Jedi Master', 'Blue', 'Stewjon', 13400),
    ('Yoda', 'Grand Master', 'Green', 'Unknown', 17700),
    ('Mace Windu', 'Jedi Master', 'Purple', 'Haruun Kal', 12800);
    
    INSERT INTO jedi_missions (mission_name, mission_type, start_date, end_date, status, jedi_id)
    VALUES
    ('Rescue from Death Star', 'Rescue', '3977-05-25', '3977-05-25', 'Completed', 1),
    ('Training on Dagobah', 'Training', '3980-05-17', '3980-06-20', 'Completed', 1),
    ('Confrontation at Cloud City', 'Combat', '3980-06-15', '3980-06-15', 'Failed', 1),
    ('Negotiation on Naboo', 'Diplomacy', '3970-06-15', '3970-06-20', 'Completed', 2);
    "
    
    # Create a database user for discovery
    sudo -u postgres psql -c "CREATE USER jedi_discovery WITH PASSWORD 'J3d1D1sc0v3ryP@ss!';"
    sudo -u postgres psql -c "GRANT CONNECT ON DATABASE jedi_records TO jedi_discovery;"
    sudo -u postgres psql -d jedi_records -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO jedi_discovery;"
    
    # Configure PostgreSQL to allow external connections
    sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
    
    # Add client authentication rule
    echo "host all all 10.0.0.0/16 md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
    
    # Restart PostgreSQL to apply changes
    sudo systemctl restart postgresql
  EOT

  service_account {
    email  = "empire-osconfig-sa@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

# Linux MID Server (unx-mid01)
resource "google_compute_instance" "unx_mid01" {
  name         = "unx-mid01"
  machine_type = var.instance_types["unx-mid01"]
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.public_subnet_ids[0]
    access_config {
      // Ephemeral IP
    }
  }

  tags = [var.firewall_tags["mandalorian_security"]]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    
    # Update packages
    apt update && apt upgrade -y
    
    # Create discovery user with sudo privileges
    useradd -m -s /bin/bash rebel-discovery-user
    echo "rebel-discovery-user:R3belD1sc0v3ryP@ss!" | chpasswd
    echo "rebel-discovery-user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/rebel-discovery-user
    chmod 0440 /etc/sudoers.d/rebel-discovery-user
    
    # Configure SSH for discovery
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    
    # Configure DNS resolution to use domain controller
    echo "nameserver ${var.domain_controller_ip}" > /etc/resolv.conf
    echo "search starwars.local" >> /etc/resolv.conf
    
    # Install Java for MID Server
    apt install -y openjdk-11-jre-headless
    
    # Create MID Server directory
    mkdir -p /opt/servicenow/mid-server
    chown $(whoami):$(whoami) /opt/servicenow/mid-server
    
    # Install gcloud and utilities
    apt install -y unzip wget git jq python3-pip curl
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    apt update && apt install -y google-cloud-sdk
    pip3 install google-cloud-secret-manager
    
    # Create a script to retrieve secrets
    cat > /opt/servicenow/get-discovery-credentials.py <<'PYTHONSCRIPT'
    #!/usr/bin/env python3
    
    from google.cloud import secretmanager
    import json
    import os
    
    def get_secret(secret_id):
        project_id = "${var.project_id}"  # Your GCP project ID
        client = secretmanager.SecretManagerServiceClient()
        name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
        
        try:
            response = client.access_secret_version(request={"name": name})
            payload = response.payload.data.decode("UTF-8")
            return json.loads(payload)
        except Exception as e:
            print(f"Error retrieving secret {secret_id}: {str(e)}")
            return None
    
    # Environment name
    environment = "hackathon"
    
    # Get Windows credentials
    windows_creds = get_secret(f"{environment}-windows-discovery-credentials")
    if windows_creds:
        with open("/opt/servicenow/windows_credentials.json", "w") as f:
            json.dump(windows_creds, f)
    
    # Get Linux credentials
    linux_creds = get_secret(f"{environment}-linux-discovery-credentials")
    if linux_creds:
        with open("/opt/servicenow/linux_credentials.json", "w") as f:
            json.dump(linux_creds, f)
    
    # Get database credentials
    db_creds = get_secret(f"{environment}-database-discovery-credentials")
    if db_creds:
        with open("/opt/servicenow/database_credentials.json", "w") as f:
            json.dump(db_creds, f)
    PYTHONSCRIPT
    
    chmod +x /opt/servicenow/get-discovery-credentials.py
    
    # Create a service to run this script periodically
    cat > /etc/systemd/system/discovery-credentials.service <<SERVICEFILE
    [Unit]
    Description=Fetch Discovery Credentials
    After=network.target
    
    [Service]
    Type=oneshot
    ExecStart=/opt/servicenow/get-discovery-credentials.py
    User=$(whoami)
    Group=$(whoami)
    
    [Install]
    WantedBy=multi-user.target
    SERVICEFILE
    
    cat > /etc/systemd/system/discovery-credentials.timer <<TIMERFILE
    [Unit]
    Description=Run discovery credentials fetch periodically
    
    [Timer]
    OnBootSec=30
    OnUnitActiveSec=3600
    
    [Install]
    WantedBy=timers.target
    TIMERFILE
    
    systemctl daemon-reload
    systemctl enable discovery-credentials.timer
    systemctl start discovery-credentials.timer
    
    # Run it once immediately
    /opt/servicenow/get-discovery-credentials.py
  EOT

  service_account {
    email  = var.mid_server_service_account
    scopes = ["cloud-platform"]
  }
}

# Windows MID Server (win-mid01)
resource "google_compute_instance" "win_mid01" {
  name         = "win-mid01"
  machine_type = var.instance_types["win-mid01"]
  zone         = "${var.region}-b"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2019"
      size  = 50
    }
  }

  network_interface {
    subnetwork = var.public_subnet_ids[1]
    access_config {
      // Ephemeral IP
    }
  }

  tags = [var.firewall_tags["imperial_security"]]

  metadata = {
    windows-startup-script-ps1 = <<-EOT
      # Set Administrator password more reliably
      net user Administrator "Emp1reP@ss123!" /active:yes
      
      # Create local discovery admin user
      $Password = ConvertTo-SecureString "Emp1reD1sc0v3ryP@ss!" -AsPlainText -Force
      New-LocalUser -Name "discadmin" -Password $Password -FullName "Discovery Admin" -Description "Local admin for ServiceNow discovery"
      Add-LocalGroupMember -Group "Administrators" -Member "discadmin"
      
      # Configure DNS to use the domain controller
      $interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
      Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses "${var.domain_controller_ip}"
      
      # Create MID Server directory
      New-Item -Path "C:\\ServiceNow" -ItemType Directory -Force
      
      # Install Java for MID Server
      [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
      Invoke-WebRequest -Uri "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=246471_2dee051a5d0647d5be72a7c0abff270e" -OutFile "C:\\java11.exe"
      Start-Process -FilePath "C:\\java11.exe" -ArgumentList "/s" -Wait
      
      # Enable WinRM for discovery
      Enable-PSRemoting -Force
      Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value "*" -Force
      Set-Service WinRM -StartupType Automatic
      Start-Service WinRM
      
      # Enable RDP
      Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name "fDenyTSConnections" -Value 0
      Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    EOT
  }

  service_account {
    email  = var.mid_server_service_account
    scopes = ["cloud-platform"]
  }
}

# Create two instance groups for MID servers (one per zone)
resource "google_compute_instance_group" "mid_server_group_a" {
  name = "rebel-fleet-group-a"
  description = "MID Server instance group for zone A"
  zone = "${var.region}-a"
  instances = [
    google_compute_instance.unx_mid01.id
  ]

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "mid-server"
    port = 8085
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create second instance group for zone B
resource "google_compute_instance_group" "mid_server_group_b" {
  name = "rebel-fleet-group-b"
  description = "MID Server instance group for zone B"
  zone = "${var.region}-b"
  instances = [
    google_compute_instance.win_mid01.id
  ]

  named_port {
    name = "http"
    port = 80
  }

  named_port {
    name = "mid-server"
    port = 8085
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Windows App Server - Old Generation (win-app01)
resource "google_compute_instance" "win_app01" {
  name         = "win-app01"
  machine_type = var.instance_types["win-app01"]
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2019"
      size  = 50
    }
  }

  network_interface {
    subnetwork = var.private_subnet_ids[0]
  }

  tags = [var.firewall_tags["imperial_security"]]

  metadata = {
    windows-startup-script-ps1 = <<-EOT
    # Set Administrator password more reliably
    net user Administrator "Emp1reP@ss123!" /active:yes

    # Create local discovery admin user for pre-domain discovery
    $Password = ConvertTo-SecureString "Emp1reD1sc0v3ryP@ss!" -AsPlainText -Force
    New-LocalUser -Name "discadmin" -Password $Password -FullName "Discovery Admin" -Description "Local admin for ServiceNow discovery"
    Add-LocalGroupMember -Group "Administrators" -Member "discadmin"

    # Install IIS
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools

    # Create test page
    Set-Content -Path "C:\\inetpub\\wwwroot\\index.html" -Value "<html><body><h1>Imperial Hologram Server (Old Gen)</h1></body></html>"

    # Enable WinRM for discovery
    Enable-PSRemoting -Force
    Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value "*" -Force
    Set-Service WinRM -StartupType Automatic
    Start-Service WinRM

    # Set DNS to point to domain controller (more reliably)
    $interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses "${var.domain_controller_ip}"

    # Test DNS resolution before attempting domain join
    $testScript = @'
    # Test DNS resolution
    while ($true) {
      if (Resolve-DnsName -Name win-dc01.starwars.local -ErrorAction SilentlyContinue) {
        Write-Host "DNS resolution working, proceeding with domain join"
        break
      }
      Write-Host "Waiting for DNS resolution to domain controller..."
      Start-Sleep -Seconds 30
    }

    # Join the domain with NetBIOS-compatible name
    $domain = "starwars.local"
    $username = "STARWARS\\Administrator"
    $password = ConvertTo-SecureString "Emp1reP@ss123!" -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    Add-Computer -DomainName $domain -Credential $credential -Restart -Force -ErrorAction SilentlyContinue
    '@ | Out-File C:\\join-domain.ps1

    # Create scheduled task to run after boot
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File "C:\\join-domain.ps1"'
    $trigger = New-ScheduledTaskTrigger -AtStartup
    Register-ScheduledTask -TaskName "Join-Domain" -Action $action -Trigger $trigger -User "SYSTEM" -RunLevel Highest

    # Download and install Java 8
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "https://javadl.oracle.com/webapps/download/AutoDL?BundleId=246471_2dee051a5d0647d5be72a7c0abff270e" -OutFile "C:\\java8.exe"
    Start-Process -FilePath "C:\\java8.exe" -ArgumentList "/s" -Wait

    # Enable RDP
    Set-ItemProperty -Path 'HKLM:\\System\\CurrentControlSet\\Control\\Terminal Server' -Name "fDenyTSConnections" -Value 0
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
    EOT
  }

  service_account {
    email  = "empire-osconfig-sa@${var.project_id}.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

# Windows App Server - New Generation (win-app02)
resource "google_compute_instance" "win_app02" {
  name         = "win-app02"
  machine_type = var.instance_types["win-app02"]
  zone         = "${var.region}-a"
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = "windows-cloud/windows-2022"
      size  = 50
    }
  }

  network_interface {
    subnetwork = var.private_subnet_ids[0]
  }

  tags = [var.firewall_tags["imperial_security"]]

  metadata = {
    windows-startup-script-ps1 = <<-EOT
    # Set Administrator password more reliably
    net user Administrator "Emp1reP@ss123!" /active:yes

    # Create local discovery admin user for pre-domain discovery
    $Password = ConvertTo-SecureString "Emp1reD1sc0v3ryP@ss!" -AsPlainText -Force
    New-LocalUser -Name "discadmin" -Password $Password -FullName "Discovery Admin" -Description "Local admin for ServiceNow discovery"
    Add-LocalGroupMember -Group "Administrators" -Member "discadmin"

    # Install IIS
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools

    # Create test page
    Set-Content -Path "C:\\inetpub\\wwwroot\\index.html" -Value "<html><body><h1>Imperial Hologram Server (New Gen)</h1></body></html>"

    # Create security software simulation
    New-Item -Path "C:\\Program Files\\BlastShield" -ItemType Directory -Force
    Set-Content -Path "C:\\Program Files\\BlastShield\\version.txt" -Value "4.5.2"
    New-Item -Path "C:\\Program Files\\BlastShield\\bin" -ItemType Directory -Force
    New-Item -Path "C:\\Program Files\\BlastShield\\conf" -ItemType Directory -Force
    Set-Content -Path "C:\\Program Files\\BlastShield\\conf\\shield.conf" -Value "mode=active\nserver=deathstar.starwars.local\ninterval=5"

    # Enable WinRM for discovery
    Enable-PSRemoting -Force
    Set-Item WSMan:\\localhost\\Client\\TrustedHosts -Value "*" -Force
    Set-Service WinRM -StartupType Automatic
    Start-Service WinRM

    # Set DNS to point to domain controller (more reliably)
    $interfaceIndex = (Get-NetAdapter | Where-Object {$_.Status -eq "Up"}).InterfaceIndex
    Set-DnsClientServerAddress -InterfaceIndex $interfaceIndex -ServerAddresses "${var.domain_controller_ip}"

    # Test DNS resolution before attempting domain join
    $testScript = @'
    # Test DNS resolution
    while ($true) {
      if (Resolve-DnsName -Name win-dc01.starwars.local -ErrorAction SilentlyContinue) {
        Write-Host "DNS resolution working, proceeding with domain join"
        break
      }
      Write-Host "Waiting for DNS resolution to domain controller..."
      Start-Sleep -Seconds 30
    }
    '@ | Out-File C:\\join-domain.ps1
    EOT
  }
}
