### PARAMETERS
param (
[STRING]$username,         
[STRING]$password,         
[STRING]$hostname,
[STRING]$vmname,
[STRING]$sshPort,
[STRING]$distroname
)
    ### NIEUWE PARAMETERS
    $downloadsPath = "C:\Users\Public\Downloads"
    $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

    #CREDENTIALS AANMAKEN VOOR POSH-SSH
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword

    #FUNCTIE OM TE BEPALEN WELKE NETPLANCONFIGURATIE GEBRUIKT MOET WORDEN
    function Choose-Netplan {
        param(
            [STRING]$distroname
        )
        $baseUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux"
    
        switch ($distroname) {
            "ubuntu" {
                $netplanUrl = "$baseUrl/ubuntu/50-cloud-init.yaml"
                $netplanOutput = "/home/ubuntu/netplan/50-cloud-init.yaml"
            }
            "debian" {
                $netplanUrl = "$baseUrl/debian/interfaces"
                $netplanOutput = "/home/debian/netplan/interfaces"
            }
            default {
                Write-Warning "Geen standaard credentials gevonden voor distributienaam: $distroname"
                $netplanUrl = $null
                $netplanoutput = $null
            }
        }
    
        return @{
            netplanUrl = $netplanUrl
            netplanOutput = $netplanOutput
        }
    }
    
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
        $SSHSession = New-SSHSession -ComputerName $ComputerName -Port $Port -Credential $Credential -AcceptKey -Force

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

    #NETPLAN KIEZEN
    $netplanInformation = Choose-Netplan -distroname $distroname
    #FUNCTIE AANROEPEN OM COMMANDO'S UIT TE VOEREN
    poshSSHcommand -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential -commands @(
        "sudo apt update",
        #"sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y",  #Na het uitvoeren van dit script moet de upgrade gedaan worden door de gebruiker.
        "sudo apt install -y bzip2 tar",                        #Bzip wordt geïnstalleerd ter voorbereiding voor guestadditions     
        "sudo apt install -y curl",                             
        "sudo mount /dev/cdrom /mnt,                            #Gebruiker kan na afloop van het script naar de directory /mnt gaan en daar het commando "sh ./VBoxLinuxAdditions.run" uitvoeren om guestadditions te installeren. 
        "mkdir /home/$hostname/netplan",                        
        "mkdir /home/$hostname/scripts",
        "curl $($netplanInformation.netplanUrl) > $($netplanInformation.netplanOutput)"            
    )
