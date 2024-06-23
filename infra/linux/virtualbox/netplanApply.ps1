### PARAMETERS
param (
[STRING]$username = "",         #DEFAULT USER
[STRING]$password = "",         #DEFAULT WACHTWOORD
[STRING]$hostname = "",
[STRING]$vmname   = "",
[STRING]$sshPort = ""
)
    $downloadsPath = "C:\Users\Public\Downloads"
    $localNetplanPath = "$downloadsPath\50-cloud-init.yaml"
    #POSH-SSH CONFIGUREREN
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
    
    #CHECK OF SSH MOGELIJK IS
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

    write-host "NU WORDT HET NETPLAN OVERGEKOPIEERD EN TOEGEPAST OP $vmname" -ForegroundColor DarkRed
    VboxManage guestcontrol $vmname mkdir "/home/$hostname/netplan" --username $Username --password $Password

    Write-Host "NETPLAN OVERKOPIEREN EN UITVOEREN" -ForegroundColor DarkRed
    VBoxManage guestcontrol $vmname copyto "$localNetplanPath\50-cloud-init.yaml"  --target-directory "/home/$hostname/netplan/50-cloud-init.yaml" --username $username --password $password
    VBoxManage guestcontrol $vmname execute --image "/bin/bash" --username $username --password $password --wait-exit --wait-stdout --verbose -- /bin/bash -c "sudo mv '/home/$hostname/netplan/50-cloud-init.yaml' '/etc/netplan/50-cloud-init.yaml"
    VBoxManage guestcontrol $vmname execute --image "/bin/bash" --username $username --password $password --wait-exit --wait-stdout --verbose -- /bin/bash -c "sudo netplan apply"
