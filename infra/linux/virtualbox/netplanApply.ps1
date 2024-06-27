### PARAMETERS
param (
[STRING]$username,         
[STRING]$password,         
[STRING]$hostname,
[STRING]$vmname,
[STRING]$sshPort
)
    $downloadsPath = "C:\Users\Public\Downloads"
    $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

    #CREDENTIALS AANMAKEN VOOR POSH-SSH
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
    
    #FUNCTIE OM SSH BESCHIKBAARHEID TE CHECKEN
    function Check-SSHAvailability {
    param(
        [string] $ComputerName,
        [int] $Port,
        [PSCredential] $Credential
    )

    $SSHAvailable = $false
    $sshCounter = 0

    while (-not $SSHAvailable) {
        Start-Sleep -Seconds 10
        try {            
            $testSSH = New-SSHSession -ComputerName $ComputerName -Port $Port -Credential $Credential -AcceptKey -Force
            if ($testSSH.SessionId -ne $null) {
                $SSHAvailable = $true
                Remove-SSHSession -SessionId $testSSH.SessionId
            }
        } catch {
            $sshCounter++
            Write-Host "$sshCounter - Wachten tot SSH beschikbaar is..."
        }
    }

    Write-Host "SSH is beschikbaar." -ForegroundColor Green
}

    #FUNCTIE OM COMMANDO'S OVER POSHSSH UIT TE VOEREN
    function poshSSHcommand {
        param (
            [string]$ComputerName,
            [int]$Port,
            [PSCredential]$Credential,
            [string[]]$Commands
        )

        #SSH SESSIE MAKEN MET POSH-SSH
        $SSHSession = New-SSHSession -ComputerName $ComputerName -Port $Port -Credential $Credential -AcceptKey

        #CHECKEN OF SSHSESSIE CORRECT IS AANGEMAAKT
        if ($SSHSession -ne $null) 
        {
            Write-Host "SSH sessie succesvol aangemaakt. SessionId: $($SSHSession.SessionId)" -ForegroundColor yellow
        }

        #IEDERE COMMANDO UITVOEREN EN OUTPUT DAARVAN TONEN
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

        #SSH SESSIE VERWIJDEREN
        Remove-SSHSession -SessionId $SSHSession.SessionId
    }

    #FUNCTIE AANROEPEN OM SSH CONNECTIE TE TESTEN
    Check-SSHAvailability -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential

    #FUNCTIE AANROEPEN OM COMMANDO'S UIT TE VOEREN
    poshSSHcommand -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential -commands @(
        "sudo apt update",
        #"sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",
        "sudo apt install -y bzip2 tar",
        "sudo mount /dev/cdrom /mnt",
        "mkdir /home/$hostname/netplan",
        "curl https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/ubuntu/50-cloud-init.yaml > /home/$hostname/netplan/50-cloud-init.yaml"            
    )
