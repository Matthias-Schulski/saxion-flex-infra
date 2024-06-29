### PARAMETERS
param (
[STRING]$vmname,                   
[STRING]$distroname,               
[STRING]$applications,             
[STRING]$sshport                   
)
    ### NIEUWE PARAMETERS
    $downloadsPath = "C:\Users\Public\Downloads"

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
    
    function Set-VMCredentials {
        param(
            [string] $distroname
        )
    
        switch ($distroname) {
            "ubuntu" {
                $username = "ubuntu"
                $password = "ubuntu"
                $hostname = "ubuntu"
            }
            "debian" {
                $username = "debian"
                $password = "debian"
                $hostname = "debian"
            }
            #"alpine" {
            #    $username = "alpine"
            #    $password = "alpine"
            #    $hostname = "alpine"
            #}
            default {
                Write-Warning "Geen standaard credentials gevonden voor distributienaam: $distroname"
                $username = $null
                $password = $null
                $hostname = $null
            }
        }
    
        return @{
            Username = $username
            Password = $password
            Hostname = $hostname
        }
    }

    $VMcredentials = Set-VMCredentials -distroname $distroname
    
    # Naconfiguratie en netwerk script downloaden 
    $postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/installApplications.ps1"
    $installApplicationsPath = "$downloadsPath\installApplications.ps1"
    Download-File -url $postConfigScriptUrl -output $installApplicationsPath
    
    $postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/netplanApply.ps1"
    $netplanApplyPath = "$downloadsPath\netplanApply.ps1"
    Download-File -url $postConfigScriptUrl -output $netplanApplyPath
    
    write-host "VMName: $vmname`nDistroname: $distroname`nApplications: $applications`nsshPort: $sshPort`nUsername: $($VMcredentials.username)`nPassword: $($VMcredentials.password)`nHostname: $($VMcredentials.hostname)" -ForegroundColor Yellow

    #NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$vmname netplan configureren." -ForegroundColor Yellow
    & "$netplanApplyPath" -username $($VMcredentials.username) -password $($VMcredentials.password) -hostname $($VMcredentials.hostname) -vmname $vmname -sshport $sshport -distroname $distroname.ToLower()
    
    #INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$vmname krijgt nu guestadditions en applicatie." -ForegroundColor Yellow
    & "$installApplicationsPath" -username $($VMcredentials.username) -password $($VMcredentials.password) -hostname $($VMcredentials.hostname) -vmname $VMName -applications $applications -sshPort $sshPort -distroname $distroname.ToLower()
