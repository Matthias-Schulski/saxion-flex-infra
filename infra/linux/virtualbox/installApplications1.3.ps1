### PARAMETERS
param (
[STRING]$username,              #DEFAULT USER
[STRING]$password,              #DEFAULT WACHTWOORD
[STRING]$hostname,              #VORIGE SCRIPT
[STRING]$vmname,                #VORIGE SCRIPT 
[STRING]$applications,          #VORIGE SCRIPT 
[STRING]$hostport               #VORIGE SCRIPT
)

    write-host "installApplications1.3.ps1" -foregroundcolor cyan
    Write-Host "$applications = applicaties"
    $baseUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/ubuntu/scripts/nginx/"
    $counter     = 0
    $scriptsPath = (Join-Path -Path $PSScriptRoot -ChildPath "SCRIPTS")
    $applCounter = 0
    
    #APPLICATIES IN ARRAY ZETTEN
    $appsArray = $applications -split ", "
    for ($i = 0; $i -lt $appsArray.Length; $i++) {
        $appsArray[$i] = $appsArray[$i].Trim()
    }

    foreach ($app in $appsArray)
    {
        Write-Host $app -ForegroundColor Cyan
    }

    #DIRECTORY AANMAKEN VOOR SCRIPTS IN VM
    write-host "Directory aanmaken in VM (scripts)" -ForegroundColor Yellow
    VboxManage guestcontrol $vmname mkdir "/home/$hostname/scripts" --username $username --password $password
    Write-Host "Directory aangemaakt" -ForegroundColor Green

    #TE INSTALLEREN SCRIPTS LATEN ZIEN
    write-host "De volgende applicaties zullen geïnstalleerd worden op deze virtuele machine:" -ForegroundColor Yellow
    Write-Host "VM Name: $vmname" -ForegroundColor Cyan
    foreach ($app in $appsArray) {
        $applCounter++
        Write-Host "$applCounter - $app" -ForegroundColor Green
    }

    ###### SCRIPTS AANROEPEN WANNEER PAD BESTAAT ########
    foreach ($app in $appsArray) {
        $appFolderPath = Join-Path -Path $scriptsPath -ChildPath $app
    
        if (Test-Path $appFolderPath -PathType Container) {
            $scripts = Get-ChildItem -Path $appFolderPath -Filter "*.ps1" -File
        
            foreach ($script in $scripts) {
                #PARAMETERS MEEGEVEN VOOR ALLE INSTALLSCRIPTS
                $arguments = @(
                    "-VMName", $vmname,
                    "-Username", $Username,
                    "-Password", $Password
                )
            
                #AANROEPEN INSTALLSCRIPTS MET PARAMETERS.
                & pwsh -File $script.FullName @arguments
            }
        } else {
            Write-Host "Geen scripts gevonden voor applicatie $app" -ForegroundColor DarkRed
        }
    }
