# Variabele voor config script
[string]$ConfigUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/course2.json"

# Tijdelijk wijzig de Execution Policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Pad naar het bestand dat het studentnummer opslaat
$studentNumberFilePath = "$env:Public\student_number.txt"

# Controleer of het studentnummer al is opgeslagen
if (Test-Path $studentNumberFilePath) {
    $studentNumber = Get-Content $studentNumberFilePath -Raw
    Write-Output "Using stored student number: $studentNumber"
} else {
    # Vraag het studentennummer op
    $studentNumber = Read-Host "Please enter your student number"
    # Sla het studentnummer op
    Set-Content -Path $studentNumberFilePath -Value $studentNumber
}

# Functie om een bestand te downloaden
function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    try {
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $output)
        Write-Output "Downloaded file from $url to $output"
    } catch {
        Write-Output "Failed to download file from $url to $output"
        throw
    }
}

# Controleer of het script opnieuw gestart moet worden
$restartFlagFile = "$env:Public\restart_flag.txt"

if (-not (Test-Path $restartFlagFile)) {
    ###########################ALGEMEEN#########################

    # Installatie van PowerShell 7
    [string]$InstallPowershell7ScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/main/pwsh7install.ps1"
    $installPowershell7ScriptPath = "$env:Public\Downloads\InstallPowershell7.ps1"

    # Download en voer het PowerShell 7 installatie script uit
    Download-File -url $InstallPowershell7ScriptUrl -output $installPowershell7ScriptPath
    & powershell -File $installPowershell7ScriptPath

    # Maak een flag-bestand om aan te geven dat de installatie van PowerShell 7 voltooid is
    New-Item -ItemType File -Path $restartFlagFile

    # Herstart PowerShell met pwsh
    Start-Process pwsh -ArgumentList "-File `"$PSCommandPath`""
    exit
} else {
    # Verwijder het flag-bestand
    Remove-Item $restartFlagFile
}

# Installeer Dependencies
[string]$GeneralScriptUrl = "https://raw.githubusercontent.com/Stefanfrijns/HBOICT/main/Virtualbox/Installdependencies.ps1"
$generalScriptPath = "$env:Public\Downloads\GeneralScript.ps1"
Download-File -url $GeneralScriptUrl -output $generalScriptPath
& pwsh -File $generalScriptPath

# Download het config.json bestand
$configLocalPath = "$env:Public\Downloads\config.json"
Download-File -url $ConfigUrl -output $configLocalPath

############################LINUX############################

$linuxMainScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/linuxHead.ps1"
$linuxMainScriptPath = "$env:Public\Downloads\LinuxMainScript.ps1"
Download-File -url $linuxMainScriptUrl -output $linuxMainScriptPath
& pwsh -File $linuxMainScriptPath -studentNumber $studentNumber -configPath $configLocalPath

###########################WINDOWS###########################

$windowsMainScriptUrl = "voeg hier de url neer"
$windowsMainScriptPath = "$env:Public\Downloads\WindowsMainScript.ps1"
Download-File -url $windowsMainScriptUrl -output $windowsMainScriptPath
& pwsh -File $windowsMainScriptPath -studentNumber $studentNumber -configPath $configLocalPath

# Herstel de oorspronkelijke Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Output "Script execution completed successfully."
