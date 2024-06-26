### PARAMETERS
param (
[STRING]$username,              #DEFAULT USER
[STRING]$password,              #DEFAULT WACHTWOORD
[STRING]$hostname,              #VORIGE SCRIPT
[STRING]$vmname,                #VORIGE SCRIPT 
[STRING]$applications,          #VORIGE SCRIPT 
[STRING]$sshPort               #VORIGE SCRIPT
)
    #FUNCTIE OM SSH CONNECTIE OP TE ZETTEN EN COMMANDO'S UIT TE VOEREN
    function poshSSHcommand {
        param (
            [string]$ComputerName,
            [int]$Port,
            [PSCredential]$Credential,
            [string[]]$Commands
        )

        #SSH SESSIE MAKEN MET POSH-SSH
        $SSHSession = New-SSHSession -ComputerName $ComputerName -Port $Port -Credential $Credential -AcceptKey

        # Check if session is successfully created
        if ($SSHSession -ne $null) 
        {
            Write-Host "SSH sessie succesvol aangemaakt. SessionId: $($SSHSession.SessionId)" -ForegroundColor yellow
        }

        # Execute each command and capture the output
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

        # Remove the SSH session
        Remove-SSHSession -SessionId $SSHSession.SessionId
    }

    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword

    write-host "installApplications1.3.ps1" -foregroundcolor cyan
    Write-Host "$applications = applicaties"
    $baseUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/ubuntu/scripts/"
    $applCounter = 0
    
    #APPLICATIES IN ARRAY ZETTEN
    $appsArray = $applications -split ","
    for ($i = 0; $i -lt $appsArray.Length; $i++) {
        $appsArray[$i] = $appsArray[$i].Trim()
    }
    
    #DIRECTORY AANMAKEN VOOR SCRIPTS IN VM
    write-host "Directory aanmaken in VM (scripts)" -ForegroundColor Yellow
    VboxManage guestcontrol $vmname mkdir "/home/$hostname/scripts" --username $username --password $password
    Write-Host "Directory aangemaakt" -ForegroundColor Green

    #TE INSTALLEREN SCRIPTS LATEN ZIEN
    write-host "De volgende applicaties zullen geïnstalleerd worden op deze virtuele machine:" -ForegroundColor Yellow
    Write-Host "VM Name: $vmname" -ForegroundColor Cyan

    ###### SCRIPTS AANROEPEN WANNEER PAD BESTAAT ########
    foreach ($app in $appsArray) {
        $applCounter++
        $scriptName = "$($app.ToLower()).sh"
        $scriptUrl = "$baseUrl$scriptName"
        $scriptpath = "home/$hostname/scripts/$scriptName"
        Write-Host $applCounter "-" $app
        Write-Host $scriptUrl -ForegroundColor DarkRed
        Write-Host $scriptpath -ForegroundColor DarkRed
        poshSSHcommand -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential -Commands @(
            "curl $scriptUrl > /home/ubuntu/scripts/$scriptName",
            "cd /home/ubuntu/scripts; chmod +x $scriptName",
            "ls /home/ubuntu/scripts",
            "cd /home/ubuntu/scripts; ./$scriptname"
        )    
    }
