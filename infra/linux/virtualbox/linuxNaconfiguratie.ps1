#### SITUATIE: VMS GEMAAKT
#### NA CONFIGURATIE MOET GEDAAN WORDEN
### PARAMETERS DIE EIGENLIJK UIT VORIGE SCRIPT MOETEN KOMEN
param (
[STRING]$vmname,                   #WORDT GELEVERD
[STRING]$distroname,               #WORDT GELEVERD
[STRING]$applications,               #WORDT GELEVERD
[STRING]$sshport                    #WORDT GELEVERD
)

function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    if (Test-Path -Path $output) {
        write-host "Het bestand is er al: $output, download wordt overgeslagen." -foregroundcolor yellow
    } else {
        try {
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            $client = New-Object System.Net.WebClient
            $client.DownloadFile($url, $output)
            write-host "Bestand gedownload van $url naar $output" -foregroundcolor green
        } catch {
            write-host "Het is niet gelukt om bestand te downloaden van  $url naar $output" -foregroundcolor darkred
            throw
        }
    }
}
$downloadsPath = "C:\Users\Public\Downloads"
# Naconfiguratie en netwerk script downloaden 
$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/installApplications1.3.ps1"
$installApplicationsPath = "$downloadsPath\installApplications1.3.ps1"
Download-File -url $postConfigScriptUrl -output $installApplicationsPath

$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/netplanApply.ps1"
$netplanApplyPath = "$downloadsPath\netplanApply.ps1"
Download-File -url $postConfigScriptUrl -output $netplanApplyPath

# Netplan downloaden

$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/ubuntu/50-cloud-init.yaml"
$localNetplanPath =  "$downloadsPath\50-cloud-init.yaml"
download-File -url $postConfigScriptUrl -output $localNetplanPath



$username = "ubuntu" #DEFAULT USER
$password = "ubuntu" #DEFAULT WACHTWOORD
$hostname = "ubuntu" #DEFAULT DIRECTORY      

write-host "VMName: $vmname`nDistroname: $distroname`nApplications: $applications`nsshPort: $sshPort"

#foreach ($VM in $VMName)
#{
    #NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$vmname netplan configureren." -ForegroundColor Yellow
    & "$netplanApplyPath" -username $username -password $password -hostname $hostname -vmname $vmname
    
    #INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$vmname krijgt nu guestadditions en applicatie." -ForegroundColor Yellow
    & "$installApplicationsPath" -username $username -password $password -hostname $hostname -vmname $VMName -applications $applications -sshPort $sshPort
#}
