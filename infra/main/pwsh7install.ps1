# Functie om te controleren of pwsh een error geeft
function Check-PowerShell7Installed {
    try {
        & "pwsh" -NoProfile -Command '$PSVersionTable.PSVersion'
        Write-Output "PowerShell 7 is already installed."
        return $true
    } catch {
        Write-Output "pwsh command failed, indicating PowerShell 7 is not installed."
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
