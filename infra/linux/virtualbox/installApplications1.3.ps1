### PARAMETERS UIT VORIG SCRIPT
param (
[STRING]$username,
[STRING]$password,
[STRING]$hostname,
[STRING]$vmname,
[STRING]$applications,
[STRING]$sshPort,
[STRING]$distroname
)

    #CREDENTIALS MAKEN VOOR POSHSSH
    $SecurePassword = ConvertTo-SecureString -String "$password" -AsPlainText -Force
    $Credential = New-Object -TypeName PSCredential -ArgumentList $Username, $SecurePassword
    $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

    #FUNCTIE OM SSH CONNECTIE OP TE ZETTEN EN COMMANDO'S UIT TE VOEREN
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

    write-host "installApplications1.3.ps1" -foregroundcolor Magenta
    $baseUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/$distroname/scripts/"
    $applCounter = 0
    write-host "$baseurl" -foregroundcolor Magenta
    
    #APPLICATIES IN ARRAY ZETTEN
    $appsArray = $applications -split ","
    for ($i = 0; $i -lt $appsArray.Length; $i++) {
        $appsArray[$i] = $appsArray[$i].Trim()
    }
    
    #TE INSTALLEREN SCRIPTS LATEN ZIEN
    write-host "De volgende applicaties zullen geïnstalleerd worden op deze virtuele machine:" -ForegroundColor Yellow
    Write-Host "$appsArray" -ForegroundColor Yellow

    ###### SCRIPTS DOWNLOADEN NAAR VM WANNEER DEZE OP GITHUB STAAT ########
    foreach ($app in $appsArray) {
    $applCounter++
    $scriptName = "$($app.ToLower()).sh"
    $scriptUrl = "$baseUrl$scriptName"
    $basePath = "/home/$hostname/scripts/"
    $scriptpath = "$basePath$scriptName"
    Write-Host $applCounter "-" $app
    Write-Host "Script URL: $scriptUrl" -ForegroundColor DarkRed
    Write-Host $scriptname
    Write-Host "Script Path: $scriptpath" -ForegroundColor DarkRed
    poshSSHcommand -ComputerName "127.0.0.1" -Port $sshPort -Credential $credential -Commands @(
        "curl $scriptUrl > $basePath$scriptName",
        "chmod +x $scriptpath",
        "ls $basepath",
        "cd $basePath; $scriptpath"
    )
}
