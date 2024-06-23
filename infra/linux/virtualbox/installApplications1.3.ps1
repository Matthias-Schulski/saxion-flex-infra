### PARAMETERS
param (
[STRING]$username    = "",          #DEFAULT USER
[STRING]$password    = "",          #DEFAULT WACHTWOORD
[STRING]$hostname    = "",          #VORIGE SCRIPT
[STRING]$vmname      = "",          #VORIGE SCRIPT 
[STRING]$applications = "",       #VORIGE SCRIPT 
[STRING]$hostport= ""               #VORIGE SCRIPT
)

    $counter     = 0
    $scriptsPath = (Join-Path -Path $PSScriptRoot -ChildPath "SCRIPTS")
    $applCounter = 0

    #DIRECTORY AANMAKEN VOOR SCRIPTS IN VM
    write-host "Directory aanmaken in VM (scripts)" -ForegroundColor Yellow
    VboxManage guestcontrol $vmname mkdir "/home/$hostname/scripts" --username ubuntu --password ubuntu
    Write-Host "Directory aangemaakt" -ForegroundColor Green

    #TE INSTALLEREN SCRIPTS LATEN ZIEN
    write-host "De volgende applicaties zullen geïnstalleerd worden op deze virtuele machine:" -ForegroundColor Yellow
    Write-Host "VM Name: $vmname" -ForegroundColor Cyan
    foreach ($app in $applications) {
        $applCounter++
        Write-Host "$applCounter - $app" -ForegroundColor Green
    }

    ###### SCRIPTS AANROEPEN WANNEER PAD BESTAAT ########
    foreach ($app in $applications) {
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
