provider "aws" {
  profile = "your-profile-name"
  region  = "us-east-1"  # Change this to your desired AWS region
}

resource "aws_instance" "windows_server" {
  ami           = "ami-xxxxxxxxxxxxxxxxx"  # Windows Server AMI
  instance_type = "t2.micro"
  key_name      = "your-key-pair"
  subnet_id              = "subnet-xxxxxxxxxxxxxxxxx"  # Private subnet
  vpc_security_group_ids = ["sg-xxxxxxxxxxxxxxxxx"]  # Security group for the Windows Server

  root_block_device {
    volume_type = "gp2"
    volume_size = 30
  }

tags = {
  Name = "AD-Coontroller-${formatdate("YYYY-MM-DD", timestamp())}"
}
  connection {
    type        = "winrm"
    user        = "Administrator"
    password    = aws_instance.windows_server.password_data
    host        = "private_ip_of_windows_server"  # Replace with the private IP of your Windows Server
    port        = 5986  # WinRM HTTPS port
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "Write-Host 'Installing IIS'",
      "Install-WindowsFeature -Name Web-Server",
      "Write-Host 'Installing AD DS'",
      "Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools",
      "Write-Host 'Configuring AD DS'",
      "Install-ADDSForest -DomainName yourdomain.local -DomainMode Win2012R2 -ForestMode Win2012R2 -InstallDns -Force",
      "Write-Host 'Installing AD LDS'",
      "Install-WindowsFeature -Name ADLDS -IncludeManagementTools",
      "Write-Host 'Configuring AD LDS'",
      "Install-ADLDSInstance -InstanceName LDSInstance -Force",
      "Write-Host 'Restarting the computer'",
      "Restart-Computer -Force"
    ]
  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.windows_server.password_data} > password.txt"
  }
}

output "private_ip" {
  value = aws_instance.windows_server.private_ip
}

output "instance_id" {
  value = aws_instance.windows_server.id
}
