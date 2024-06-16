# Variabele voor config script
[string]$ConfigUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/course3.json"
[string]$VHDLinksUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/harddisks2.json"

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

# Functie om het OS-type te bepalen
function Get-OSType {
    param (
        [string]$osName
    )
    if ($osName -match "Ubuntu") {
        return "Ubuntu_64"
    } elseif ($osName -match "Debian") {
        return "Debian_64"
    } elseif ($osName -match "Alpine") {
        return "Alpine_64"
    } else {
        return "OtherLinux_64"
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
[string]$GeneralScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/InstallDependencies.ps1"
$generalScriptPath = "$env:Public\Downloads\GeneralScript.ps1"
Download-File -url $GeneralScriptUrl -output $generalScriptPath
& pwsh -File $generalScriptPath

# Download de JSON-bestanden
$configLocalPath = "$env:Public\Downloads\config.json"
$vhdLinksLocalPath = "$env:Public\Downloads\vhdlinks.json"
Download-File -url $ConfigUrl -output $configLocalPath
Download-File -url $VHDLinksUrl -output $vhdLinksLocalPath

# Lees de JSON configuratie
$config = Get-Content $configLocalPath -Raw | ConvertFrom-Json
$vhdLinks = Get-Content $vhdLinksLocalPath -Raw | ConvertFrom-Json

# Map to store OS to VHD URL
$vhdUrlMap = @{}
foreach ($vhdLink in $vhdLinks) {
    $vhdUrlMap[$vhdLink.OS] = $vhdLink.VHDUrl
}

# Controleer welke OS'en in de configuratie staan en roep de juiste scripts aan
$hasLinux = $false
$hasWindows = $false

foreach ($vm in $config.VMs) {
    if ($vm.VMVHDFile -match "Linux") {
        $hasLinux = $true
    } elseif ($vm.VMVHDFile -match "Windows") {
        $hasWindows = $true
    }
}

if ($hasLinux) {
    ############################LINUX############################
    $linuxMainScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/linuxHead.ps1"
    $linuxMainScriptPath = "$env:Public\Downloads\LinuxMainScript.ps1"
    Download-File -url $linuxMainScriptUrl -output $linuxMainScriptPath

    foreach ($vm in $config.VMs) {
        if ($vm.VMVHDFile -match "Linux") {
            $vmName = "$($vm.VMName)_$studentNumber".Trim()
            $osTypeKey = $vm.VMVHDFile
            $VHDUrl = $vhdUrlMap[$osTypeKey]
            if (-not $VHDUrl) {
                Write-Output "VHD URL not found for $osTypeKey. Skipping VM creation for $vmName."
                continue
            }
            $OSType = Get-OSType -osName $osTypeKey
            $MemorySize = $vm.VMMemorySize
            $CPUs = $vm.VMCpuCount
            $NetworkType = $vm.VMNetworkType
            $Applications = $vm.VMApplications -join ','

            # Roep het Linux hoofscript aan met de juiste parameters
            $arguments = @(
                "-VMName", $vmName,
                "-VHDUrl", $VHDUrl,
                "-OSType", $OSType,
                "-MemorySize", $MemorySize,
                "-CPUs", $CPUs,
                "-NetworkType", $NetworkType,
                "-Applications", $Applications
            )
            & pwsh -File $linuxMainScriptPath @arguments
        }
    }
}

if ($hasWindows) {
    ###########################WINDOWS###########################
    $windowsMainScriptUrl = "https://raw.githubusercontent.com/Stefanfrijns/HBOICT/main/Virtualbox/WindowsMainScript.ps1"
    $windowsMainScriptPath = "$env:Public\Downloads\WindowsMainScript.ps1"
    Download-File -url $windowsMainScriptUrl -output $windowsMainScriptPath

    foreach ($vm in $config.VMs) {
        if ($vm.VMVHDFile -match "Windows") {
            $vmName = "$($vm.VMName)_$studentNumber".Trim()
            $osTypeKey = $vm.VMVHDFile
            $VHDUrl = $vhdUrlMap[$osTypeKey]
            if (-not $VHDUrl) {
                Write-Output "VHD URL not found for $osTypeKey. Skipping VM creation for $vmName."
                continue
            }
            $OSType = Get-OSType -osName $osTypeKey
            $MemorySize = $vm.VMMemorySize
            $CPUs = $vm.VMCpuCount
            $NetworkType = $vm.VMNetworkType
            $Applications = $vm.VMApplications -join ','

            # Roep het Windows hoofscript aan met de juiste parameters
            $arguments = @(
                "-VMName", $vmName,
                "-VHDUrl", $VHDUrl,
                "-OSType", $OSType,
                "-MemorySize", $MemorySize,
                "-CPUs", $CPUs,
                "-NetworkType", $NetworkType,
                "-Applications", $Applications
            )
            & pwsh -File $windowsMainScriptPath @arguments
        }
    }
}

# Herstel de oorspronkelijke Execution Policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

Write-Output "Script execution completed successfully."
