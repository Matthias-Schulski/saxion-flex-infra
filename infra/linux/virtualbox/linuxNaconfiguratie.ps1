#### SITUATIE: VMS GEMAAKT
#### NA CONFIGURATIE MOET GEDAAN WORDEN
### PARAMETERS DIE EIGENLIJK UIT VORIGE SCRIPT MOETEN KOMEN
param (
[STRING]$VMname = "",                   #WORDT GELEVERD
[STRING]$distroname = "",               #WORDT GELEVERD
[STRING]$applications="",               #WORDT GELEVERD
[STRING]$hostport=""                    #WORDT GELEVERD
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
$postConfigScriptPath = "$downloadsPath\installApplications1.3.ps1"
Download-File -url $postConfigScriptUrl -output $postConfigScriptPath

$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/netplanApply.ps1"
$postConfigScriptPath = "$downloadsPath\netplanApply.ps1"
Download-File -url $postConfigScriptUrl -output $postConfigScriptPath

# Netplan downloaden

$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/ubuntu/50-cloud-init.yaml"
$postConfigScriptPath =  "$downloadsPath\50-cloud-init.yaml"
download-File -url $postConfigScriptUrl -output $postConfigScriptPath



$username = "ubuntu" #DEFAULT USER
$password = "ubuntu" #DEFAULT WACHTWOORD
$hostname = "ubuntu" #DEFAULT DIRECTORY                 

foreach ($VM in $VMName)
{
    #NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$vmname netplan configureren." -ForegroundColor Yellow
    & ".\netplanApply.ps1" -username $username -password $password -hostname $hostname -vmname $vmname
    
    #INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$vmname krijgt nu guestadditions en applicatie." -ForegroundColor Yellow
    & ".\installApplications1.3.ps1" -username $username -password $password -hostname $hostname -vmname $VMName -applications $applications -hostport $hostport
}

