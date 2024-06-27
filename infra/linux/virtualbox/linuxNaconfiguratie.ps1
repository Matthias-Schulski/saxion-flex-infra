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

    if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
        Install-Module Posh-SSH
    }
    
$downloadsPath = "C:\Users\Public\Downloads"
# Naconfiguratie en netwerk script downloaden 
$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/installApplications1.3.ps1"
$installApplicationsPath = "$downloadsPath\installApplications1.3.ps1"
Download-File -url $postConfigScriptUrl -output $installApplicationsPath

$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/netplanApply.ps1"
$netplanApplyPath = "$downloadsPath\netplanApply.ps1"
Download-File -url $postConfigScriptUrl -output $netplanApplyPath

if ($distroname -eq "ubuntu")
{
    $username = "ubuntu" #DEFAULT USER VOOR UBUNTU
    $password = "ubuntu" #DEFAULT WACHTWOORD VOOR UBUNTU
    $hostname = "ubuntu" #DEFAULT DIRECTORY VOOR UBUNTU  
} elseif ($distroname -eq "debian") {
    $username = "debian" #DEFAULT USER VOOR DEBIAN
    $password = "debian" #DEFAULT WACHTWOORD VOOR DEBIAN
    $hostname = "debian" #DEFAULT DIRECTORY VOOR DEBIAN
} #elseif ($distroname -eq "Alpine"){
    #$username = "alpine" #DEFAULT USER VOOR ALPINE
    #$password = "alpine" #DEFAULT WACHTWOORD VOOR ALPINE
    #$hostname = "alpine" #DEFAULT DIRECTORY VOOR ALPINE
#}

write-host "VMName: $vmname`nDistroname: $distroname`nApplications: $applications`nsshPort: $sshPort`nUsername: $username`nPassword: $password`nHostname: $hostname"

#foreach ($VM in $VMName)
#{
    #NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$vmname netplan configureren." -ForegroundColor Yellow
    & "$netplanApplyPath" -username $username -password $password -hostname $hostname -vmname $vmname -sshport $sshport
    
    #INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$vmname krijgt nu guestadditions en applicatie." -ForegroundColor Yellow
    & "$installApplicationsPath" -username $username -password $password -hostname $hostname -vmname $VMName -applications $applications -sshPort $sshPort -distroname $distroname.ToLower()
#}
