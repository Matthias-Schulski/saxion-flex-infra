###### VOORBEELD INSTALLATIE SCRIPT VOOR APPLICATIES BINNEN UBUNTU #####
###### VARIABELEN INITALISEREN #####
param (
    [string]$scriptName = "<applicataienaam>script.sh", #naam van het installscript lokaal op host
    [string]$applicationName = "<applicatienaam>",      #naam van applicatie dat geïnstalleerd zal worden
    [string]$localScriptPath = (Join-Path -Path $env:USERPROFILE -ChildPath "\VirtualBox VMs\scripts\$applicationName\$scriptName"), #locatie waar installscript staat op host
    [string]$VMName = "",           #wordt geleverd uit vorige script
    [string]$username = "",         #wordt geleverd uit vorige script
    [string]$password = "",         #wordt geleverd uit vorige script
    [string]$hostname = "ubuntu",   #wordt geleverd uit vorige script
    [string]$directoryPath = "/home/$hostname/scripts/$applicationName" #directory pad waar het script in komt te staan binnen VM
)

$applicatieInstallCheck = VBoxManage guestcontrol $VMName run --username $username --password $password --exe /bin/bash -- -c "if [ -d '$directoryPath' ]; then echo \'exists\'; else echo \'not_exists\'; fi"

#CHECKER UITVOEREN 
$uitkomst = Invoke-Expression -Command $applicatieInstallCheck

if ($uitkomst -eq "exists") {
    Write-host "$applicationName is al geïnstalleerd. Volgende applicatie installeren." -ForegroundColor Green
    exit
}

write-host "Directory aanmaken in VM ($applicationName)" -ForegroundColor Yellow
VboxManage guestcontrol $VMName mkdir "/home/$username/scripts/$applicationName" --username $username --password $password
VboxManage guestcontrol $VMName mkdir "/home/$username/$applicationName" --username $username --password $password
Write-Host "Directory $applicationName is aangemaakt" -ForegroundColor Green

#INSTALLSCRIPT VOOR APPLICATIE OVERKOPIËREN NAAR VM
write-host "installScript.sh overkopiëren naar VM ($applicationName)" -ForegroundColor Yellow
VBoxManage guestcontrol $VMName copyto $localScriptPath --target-directory "/home/$username/scripts/$applicationName/$scriptName" --username $username --password $password
Write-Host "Overgekopieerd" -ForegroundColor Green

#SCRIPT UITVOERBAAR MAKEN EN UITVOEREN OVER GUESTCONTROL
write-host "Script uitvoerbaar maken" -ForegroundColor Yellow
vboxmanage guestcontrol $VMName run --exe "/bin/chmod" --username $username --password $username --wait-stdout -- +x "/home/$username/scripts/$applicationName/$scriptName"
Write-Host "Script uitvoerbaar gemaakt" -ForegroundColor Green

write-host "Script uitvoeren" -ForegroundColor Yellow
vboxmanage guestcontrol $VMName run --exe "/bin/bash" --username $username --password $username --wait-stdout -- -c "/home/$username/scripts/$applicationName/$scriptName"
Write-Host "Scipt uitgevoerd" -ForegroundColor Green