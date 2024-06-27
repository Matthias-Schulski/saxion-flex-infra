### PARAMETERS
param (
[STRING]$username,         
[STRING]$password,         
[STRING]$hostname,
[STRING]$vmname,
[STRING]$sshPort
)
    $downloadsPath = "C:\Users\Public\Downloads"
    $localNetplanPath = "$downloadsPath\50-cloud-init.yaml"
    $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
    #POSH-SSH CONFIGUREREN
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
    
    #CHECK OF SSH MOGELIJK IS
    $SSHAvailable = $false
    $sshCounter = 0
        while (-not $SSHAvailable) {
            Start-Sleep -Seconds 10
            try {            
                $testSSH = New-SSHSession -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential -AcceptKey 
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
    
    $SSHSession = New-SSHSession -ComputerName "127.0.0.1" -Port $sshport -Credential $credential  -AcceptKey -Force

    if ($SSHSession -ne $null) {
        Write-Host "SSH sessie succesvol aangemaakt. SessionId: $($SSHSession.SessionId)" -ForegroundColor yellow
    
        # Voer de commando's een voor een uit
        $commands = @(
            "sudo apt update && sudo apt upgrade",
            "sudo apt install -y bzip2 tar",
            "sudo mount /dev/cdrom /mnt",
            "cd /mnt; sudo sh ./VBoxLinuxAdditions.run"
        )
    
        foreach ($command in $commands) 
        {
            Write-Host "Executing: $command" -ForegroundColor cyan
            $CommandResult = Invoke-SSHCommand -SessionId $SSHSession.SessionId -Command $command -TimeOut 600
        
            if ($CommandResult.ExitStatus -ne 0) {
                Write-Host "Error executing: $command" -ForegroundColor red
                Write-Host "Error details: $($CommandResult.Error)" -ForegroundColor red
                break
            } else {
                Write-Host "Command executed successfully: $command" -ForegroundColor green
                Write-Host "Result: $($CommandResult.Output)"
            }
        }
    
        # Sluit de SSH-sessie
        Remove-SSHSession -SessionId $SSHSession.SessionId
    } else {
        Write-Host "Kon geen SSH-sessie aanmaken" -ForegroundColor red
    }

    #NETPLAN OVERKOPIEREN NAAR VM ZODAT STUDENT DAAR VERDER MEE KAN.
    write-host "NU WORDT HET NETPLAN OVERGEKOPIEERD NAAR $vmname" -ForegroundColor DarkRed
    & $vboxManagePath guestcontrol $vmname mkdir "/home/$hostname/netplan" --username $Username --password $Password
    & $vboxManagePath guestcontrol $vmname copyto "$localNetplanPath"  --target-directory "/home/$hostname/netplan/50-cloud-init.yaml" --username $username --password $password
