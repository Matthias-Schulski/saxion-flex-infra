###### NGINX INSTALLATIE SCRIPT VOOR UBUNTU #####
###### VARIABELEN INITALISEREN #####
param (
    [string]$scriptName = "nginxScript.sh",
    [string]$applicationName = "nginx",
    [string]$localScriptPath = (Join-Path -Path $env:PUBLIC -ChildPath "\scripts\$applicationName\$scriptName"),
    [string]$localDefaultPath = (Join-Path -Path $env:PUBLIC -ChildPath "\scripts\$applicationName\default"),
    [string]$localIndexPath = (Join-Path -Path $env:PUBLIC -ChildPath "\scripts\$applicationName\index.html"),
    [string]$VMName = "",           #wordt geleverd uit vorige script
    [string]$username = "",         #wordt geleverd uit vorige script
    [string]$password = "",         #wordt geleverd uit vorige script
    [string]$hostname = "ubuntu",   #wordt geleverd uit vorige script
    [string]$directoryPath = "/home/$hostname/scripts/$applicationName"
)

$applicatieInstallCheck = VBoxManage guestcontrol $VMName run --username $username --password $password --exe /bin/bash -- -c "if [ -d '$directoryPath' ]; then echo \'exists\'; else echo \'not_exists\'; fi"

#CHECKER UITVOEREN 
$uitkomst = Invoke-Expression -Command $applicatieInstallCheck

if ($uitkomst -eq "exists") {
    Write-host "$applicationName is al geïnstalleerd. Volgende applicatie installeren." -ForegroundColor Green
    write-host "VMnaam: $vmname `nUser: $username `npass: $password`nappname:$applicationName" -ForegroundColor RED
    exit
}

write-host "Directory aanmaken in VM ($applicationName)" -ForegroundColor Yellow
VboxManage guestcontrol $VMName mkdir "/home/$hostname/scripts/$applicationName" --username $username --password $password
VboxManage guestcontrol $VMName mkdir "/home/$hostname/$applicationName" --username $username --password $password
Write-Host "Directory $applicationName is aangemaakt" -ForegroundColor Green

#INSTALLSCRIPT VOOR NGINX OVERKOPIËREN NAAR VM
write-host "installScript.sh overkopiëren naar VM ($applicationName)" -ForegroundColor Yellow
VBoxManage guestcontrol $VMName copyto $localScriptPath --target-directory "/home/$hostname/scripts/$applicationName/$scriptName" --username $username --password $password
Write-Host "Overgekopieerd" -ForegroundColor Green

#SCRIPT UITVOERBAAR MAKEN EN UITVOEREN OVER GUESTCONTROL
write-host "Script uitvoerbaar maken" -ForegroundColor Yellow
vboxmanage guestcontrol $VMName run --exe "/bin/chmod" --username $username --password $username --wait-stdout -- +x "/home/$hostname/scripts/$applicationName/$scriptName"
Write-Host "Script uitvoerbaar gemaakt" -ForegroundColor Green

write-host "Script uitvoeren" -ForegroundColor Yellow
vboxmanage guestcontrol $VMName run --exe "/bin/bash" --username $username --password $username --wait-stdout -- -c "/home/$hostname/scripts/$applicationName/$scriptName"
Write-Host "Scipt uitgevoerd" -ForegroundColor Green

#NACONFIGURATIE NGINX 
write-host "Naconfiguratie NGINX" -ForegroundColor Yellow
#BESTANDEN VOOR NGINX-PAGINA KOPIËREN NAAR VM
VBoxManage guestcontrol $VMName copyto $localDefaultPath --target-directory "/home/$hostname/$applicationName/default" --username $username --password $password
VBoxManage guestcontrol $VMName copyto $localIndexPath --target-directory "/home/$hostname/$applicationName/index.html" --username $username --password $password
Write-Host "Bestanden gekopieerd naar VM" -ForegroundColor Green

#DEFAULT EN INDEX.HTML VERPLAATSEN NAAR CORRECTE DIRECTORY
VBoxManage guestcontrol $VMName run --username $username --password $username --exe "/bin/bash" -- -c "echo '$username' | sudo -S cp /home/$hostname/$applicationName/default /etc/nginx/sites-available/default"
VBoxManage guestcontrol $VMName run --username $username --password $username --exe "/bin/bash" -- -c "echo '$username' | sudo -S cp /home/$hostname/$applicationName/index.html /var/www/html/index.html"
Write-Host "Bestanden verplaatst naar correcte directories" -ForegroundColor Green

#INDEX.HTML CORRECT TOEGANGSRECHTEN GEVEN
VBoxManage guestcontrol $VMName run --username $username --password $username --exe "/bin/bash" -- -c "sudo chown www-data:www-data /var/www/html/index.html"
