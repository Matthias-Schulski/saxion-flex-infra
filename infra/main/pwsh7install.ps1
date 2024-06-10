# Functie om te controleren of PowerShell 7 al is geïnstalleerd door de map te controleren
function Check-PowerShell7Installed {
    $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    Write-Output "Checking for PowerShell 7 at: $pwshPath"
    if (Test-Path $pwshPath) {
        Write-Output "Found pwsh.exe at: $pwshPath"
        return $true
    } else {
        Write-Output "pwsh.exe not found at $pwshPath, indicating PowerShell 7 is not installed."
        return $false
    }
}

# Controleer of PowerShell 7 al is geïnstalleerd
if (-not (Check-PowerShell7Installed)) {
    Write-Output "PowerShell 7 is not installed. Proceeding with installation."

    # Download en installeer PowerShell 7
    $installerUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi"
    $installerPath = "$env:TEMP\PowerShell-7.4.2-win-x64.msi"

    Write-Output "Downloading PowerShell 7 installer from $installerUrl..."
    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -ErrorAction Stop
        Write-Output "Download completed."
    } catch {
        Write-Output "Failed to download PowerShell 7 installer: $_"
        exit 1
    }

    Write-Output "Installing PowerShell 7 from $installerPath..."
    try {
        Start-Process msiexec.exe -ArgumentList "/I", $installerPath, "/quiet", "/norestart" -NoNewWindow -Wait
        Write-Output "Installation process initiated."
    } catch {
        Write-Output "Failed to start PowerShell 7 installation: $_"
        exit 1
    }

    # Controleer opnieuw of PowerShell 7 nu is geïnstalleerd
    if (Check-PowerShell7Installed) {
        Write-Output "PowerShell 7 installation completed successfully."
    } else {
        Write-Output "PowerShell 7 installation failed."
        exit 1
    }
}
