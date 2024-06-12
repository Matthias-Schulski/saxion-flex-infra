# Set variables (replace with your desired values)
$domainName = "saxtest.local"
$adminPassword = ConvertTo-SecureString ("<YourStrongPasswordHere>") -AsPlainText -Force

# Install Active Directory Domain Services role
Install-WindowsFeature -Name ActiveDirectoryDomainServices -IncludeManagementTools

# Configure Active Directory promotion
$forestMode = "New Forest"  # Choose "New Forest" or "Add Domain Controller to Existing Forest"
$safeModePassword = $adminPassword

# Run Active Directory Domain Services Installation Wizard with provided parameters
Start-Process wgaclui.exe -ArgumentList "/silent /forest:$forestMode /domain:$domainName /safeModePwd:$safeModePassword /cmd:ClearConfig" -Wait

# Script will prompt for reboot, confirm manually

# Additional configuration steps (not automated in this example)
# - DNS configuration (optional, can be configured during promotion)
# - Group Policy configuration
# - User and computer management

Write-Host "Active Directory installation initiated for $domainName. Please review logs and perform manual configuration steps."
