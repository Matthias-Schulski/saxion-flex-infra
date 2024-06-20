###### DOCKER INSTALLATIE SCRIPT VOOR UBUNTU #####
###### VARIABELEN INITALISEREN #####
param (
    [string]$scriptName = "dockerScript.sh",
    [string]$applicationName = "docker",
    [string]$localScriptPath = (Join-Path -Path $env:PUBLIC -ChildPath "\scripts\$applicationName\$scriptName"),
    [string]$VMName+"",                #wordt geleverd uit vorige script
    [string]$Username= "",              #wordt geleverd uit vorige script
    [string]$Password= "",              #wordt geleverd uit vorige script
    [string]$hostname= "ubuntu",   #wordt geleverd uit vorige script
    [string]$directoryPath = "/home/$hostname/scripts/$applicationName"
)
$applicatieInstallCheck = VBoxManage guestcontrol $VMName run --username $username --password $password --exe /bin/bash -- -c "if [ -d '$directoryPath' ]; then echo \'exists\'; else echo \'not_exists\'; fi"

#CHECKER UITVOEREN 
$uitkomst = Invoke-Expression -Command $applicatieInstallCheck
if ($uitkomst -eq "exists") {
    Write-host "$applicationName is al geïnstalleerd. Volgende applicatie installeren." -ForegroundColor Green
    write-host "VMnaam: $VMname `nUser: $username `npass: $password`nappname: $applicationName" -ForegroundColor RED
    exit
}
#DIRECTORY MAKEN 
write-host "Directory aanmaken in VM voor $applicationName" -ForegroundColor Yellow
VboxManage guestcontrol $VMname mkdir "/home/$hostname/scripts/$applicationName" --username $username --password $password
Write-Host "Directory $applicationName is aangemaakt" -ForegroundColor Green

#INSTALLSCRIPT VOOR DOCKER OVERKOPIËREN NAAR VM
write-host "installScript.sh overkopiëren naar VM ($applicationName)" -ForegroundColor Yellow
VBoxManage guestcontrol $VMname copyto $localScriptPath --target-directory "/home/$hostname/scripts/$applicationName/$scriptName" --username $username --password $password
Write-Host "$applicationName-script overgekopieerd" -ForegroundColor Green

#SCRIPT UITVOERBAAR MAKEN EN UITVOEREN OVER GUESTCONTROL
write-host "Script uitvoerbaar maken" -ForegroundColor Yellow
vboxmanage guestcontrol $VMname run --exe "/bin/chmod" --username $username --password $password --wait-stdout -- +x "/home/$hostname/scripts/$applicationName/$scriptName"
Write-Host "Script uitvoerbaar gemaakt" -ForegroundColor Green

write-host "Script uitvoeren" -ForegroundColor Yellow
vboxmanage guestcontrol $VMname run --exe "/bin/bash" --username $username --password $password --wait-stdout -- -c "/home/$hostname/scripts/$applicationName/$scriptName"
Write-Host "Scipt uitgevoerd" -ForegroundColor Green

