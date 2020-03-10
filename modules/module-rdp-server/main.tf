/******************* Instance: RDP Server ********************/

data "template_file" "userdata_win" {
  template = <<EOF
<powershell>
$SourceURL = "https://download-installer.cdn.mozilla.net/pub/firefox/releases/73.0.1/win64/en-US/Firefox%20Setup%2073.0.1.msi";
$Installer = $env:TMP + "\firefox.msi"; 
Invoke-WebRequest $SourceURL -OutFile $Installer;
Start-Process -FilePath $Installer -Args "/quiet" -Wait; 
Remove-Item $Installer;

$Path = $env:TEMP; 
$Installer = "chrome_installer.exe"; 
Invoke-WebRequest "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $Path$Installer; 
Start-Process -FilePath $Path$Installer -Args "/silent /install" -Verb RunAs -Wait; 
Remove-Item $Path$Installer

Install-PackageProvider -Name NuGet -Force;
Install-Module -Name Posh-SSH -Force;

#https://github.com/darkoperator/Posh-SSH/blob/master/docs/Get-SCPFile.md
</powershell>
<persist>false</persist>
EOF

/*
Invoke-Expression -Command 'net user ${var.windows_username} /add /y';
Invoke-Expression -Command 'net user ${var.windows_username} ${var.windows_password}';
Invoke-Expression -Command 'net localgroup administrators ${var.windows_username} /add';

$password = ConvertTo-SecureString -SecureString "${var.windows_password}"
New-LocalUser "${var.windows_username}" -Password $password -FullName "${var.windows_username}"
Add-LocalGroupMember -Group "Administrators" -Member "${var.windows_username}"
*/
}

resource "aws_instance" "rdp_server" {
  ami                    = var.rdp_ec2_ami
  instance_type          = var.rdp_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.vpc_security_group_ids
  subnet_id              = var.subnet_id
  user_data              = data.template_file.userdata_win.rendered
  get_password_data      = true

  count = var.rdp_server_enabled == true ? 1 : 0

  root_block_device {
    volume_type = "gp2"
    volume_size = 400
  }

  tags = {
    Name = "${var.project_id}-instance-rdp-server"
    Project = "${var.project_id}"
    user = "${var.user}"
  }
}