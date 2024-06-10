# Functie om te controleren of PowerShell 7 al is geïnstalleerd
function Check-PowerShell7Installed {
    $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    if (Test-Path $pwshPath) {
        try {
            $psVersion = & "$pwshPath" -NoProfile -Command '$PSVersionTable.PSVersion'
            if ($psVersion.Major -ge 7) {
                return $true
            } else {
                return $false
            }
        } catch {
            return $false
        }
    } else {
        return $false
    }
}

# Check of PowerShell 7 al is geïnstalleerd
if (Check-PowerShell7Installed) {
    Write-Output "PowerShell 7 is already installed."
} else {
    # Download en installeer PowerShell 7
    $installerUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi"
    $installerPath = "$env:TEMP\PowerShell-7.4.2-win-x64.msi"

    Write-Output "Downloading PowerShell 7 installer..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    Write-Output "Installing PowerShell 7..."
    Start-Process msiexec.exe -ArgumentList "/I", $installerPath, "/quiet", "/norestart" -NoNewWindow -Wait

    # Controleer opnieuw of PowerShell 7 nu is geïnstalleerd
    if (Check-PowerShell7Installed) {
        Write-Output "PowerShell 7 installation completed successfully."
    } else {
        Write-Output "PowerShell 7 installation failed."
    }
}
