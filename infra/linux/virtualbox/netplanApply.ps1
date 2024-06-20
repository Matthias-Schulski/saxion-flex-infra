### PARAMETERS
param (
[STRING]$username = "",         #DEFAULT USER
[STRING]$password = "",         #DEFAULT WACHTWOORD
[STRING]$hostname = "",
[STRING]$vmname   = ""
)

write-host "NU WORDT HET NETPLAN OVERGEKOPIEERD EN TOEGEPAST OP $vmname" -ForegroundColor DarkRed
VboxManage guestcontrol $vmname mkdir "/home/$hostname/netplan" --username $Username --password $Password
$localNetplanPath = (Join-Path -Path $env:USERPROFILE -ChildPath "\VirtualBox VMs\$VMName-netplan")

Write-Host "NETPLAN OVERKOPIEREN" -ForegroundColor DarkRed
VBoxManage guestcontrol $vmname copyto "$localNetplanPath\50-cloud-init.yaml"  --target-directory "/home/$hostname/netplan/50-cloud-init.yaml" --username $username --password $password