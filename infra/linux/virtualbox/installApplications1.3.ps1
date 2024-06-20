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

    #POSH-SSH CONFIGUREREN
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
    
    
    vboxmanage startvm $vmname

    $VMStarted = $false
        while (-not $VMStarted) {
            Start-Sleep -Seconds 5
            $VMInfo = & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" showvminfo $VMName --machinereadable
            # Controleer de status van de VM
            foreach ($line in $VMInfo) {
                if ($line -match 'VMState="running"') {
                    $VMStarted = $true
                    break
                    }
            }
            if (-not $VMStarted) {
                Write-Host "Wachten tot de VM is opgestart..."
        }
    }

    Write-Host "VM is opgestart en draait."

    # Wacht totdat SSH beschikbaar is
    $SSHAvailable = $false
    $sshCounter = 0
        while (-not $SSHAvailable) {
            Start-Sleep -Seconds 10
            try {            
                $testSSH = New-SSHSession -ComputerName "127.0.0.1" -Port $hostport -Credential $credential
            if ($testSSH.SessionId -ne $null) {
                $SSHAvailable = $true
                Remove-SSHSession -SessionId $testSSH.SessionId
            }
            } catch {
                $sshcounter++
                Write-Host "$sshcounter - Wachten tot SSH beschikbaar is..."
            }
    }

    Write-Host "SSH is beschikbaar." -ForegroundColor green
    
    $SSHSession = New-SSHSession -ComputerName "127.0.0.1" -Port $hostport -Credential $credential

    if ($SSHSession -ne $null) {
    Write-Host "SSH sessie succesvol aangemaakt. SessionId: $($SSHSession.SessionId)" -ForegroundColor yellow
    
    # Voer een commando uit
    $CommandResult = invoke-sshcommand -sessionid $sshsession.sessionid -command "sudo apt install -y bzip2 tar; sudo mount /dev/cdrom /mnt; cd /mnt; sudo sh ./VBoxLinuxAdditions.run"    
    # Output de resultaten van het commando
    Write-Host "Command executed. Result: $($CommandResult.Output)"
    
    # Sluit de SSH sessie
    Remove-SSHSession -SessionId $SSHSession.SessionId
    } else {
        Write-Host "Fout bij het aanmaken van de SSH sessie." -ForegroundColor DarkRed
        break
    }


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