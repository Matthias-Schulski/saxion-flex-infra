# Parameters
param (
    [string]$VMName,
    [string]$VHDUrl,
    [string]$OSType,
    [string]$DistroName,
    [int]$MemorySize,
    [int]$CPUs,
    [string]$NetworkTypes,  # JSON-string
    [string]$Applications,
    [string]$ConfigureNetworkPath
)

# Variables
$previousExecutionPolicy = Get-ExecutionPolicy
$ConfigureNetworkUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/ConfigureNetwork.ps1"
$CreateVM1Url = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/createVM.ps1"
$ModifyVMSettingsUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/ModifyVMSettings.ps1"
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$configureNetworkPath = "$env:Public\Downloads\ConfigureNetwork.ps1"
$createVM1LocalPath = "$env:Public\Downloads\CreateVM1.ps1"
$modifyVMSettingsLocalPath = "$env:Public\Downloads\ModifyVMSettings.ps1"
$createdVMsPath = "$env:Public\created_vms.txt"
$logFilePath = "$env:Public\LinuxMainScript.log"

# Temporarily change the Execution Policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Function to download a file
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

# Log function
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logFilePath -Value $logMessage
}

# Main script

# Check if VBoxManage is available
if (-not (Test-Path $vboxManagePath)) {
    Log-Message "VBoxManage not found. Ensure VirtualBox is installed."
    throw "VBoxManage not found."
}

# Download the JSON files and scripts
Download-File -url $ConfigureNetworkUrl -output $configureNetworkPath
Download-File -url $CreateVM1Url -output $createVM1LocalPath
Download-File -url $ModifyVMSettingsUrl -output $modifyVMSettingsLocalPath

# Check if the file with created VMs exists
if (-not (Test-Path $createdVMsPath)) {
    New-Item -ItemType File -Force -Path $createdVMsPath
}

# Read the list of created VMs and filter empty lines and duplicate entries
$createdVMs = Get-Content $createdVMsPath -Raw -ErrorAction SilentlyContinue | Out-String -ErrorAction SilentlyContinue
$createdVMs = $createdVMs -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" } | Sort-Object -Unique

Write-Output "List of created VMs:"
$createdVMs | ForEach-Object { Write-Output " - $_" }

Log-Message "Creating new VM: $VMName"
# Call the CreateVM1.ps1 script with the correct parameters
$arguments = @(
    "-VMName", $VMName,
    "-VHDUrl", $VHDUrl,
    "-OSType", $OSType,
    "-DistroName", $DistroName,
    "-MemorySize", $MemorySize,
    "-CPUs", $CPUs,
    "-NetworkTypes", $NetworkTypes,
    "-Applications", $Applications,
    "-ConfigureNetworkPath", $configureNetworkPath
)
& pwsh -File $createVM1LocalPath @arguments

# Add the name of the created VM to created_vms.txt
Add-Content -Path $createdVMsPath -Value $VMName

# Restore the original Execution Policy
Set-ExecutionPolicy -ExecutionPolicy $previousExecutionPolicy -Scope Process -Force

Log-Message "Script execution completed successfully."
