# Functie om te controleren of PowerShell 7 al is geïnstalleerd
function Check-PowerShell7Installed {
    $pwshPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
    Write-Output "Checking for PowerShell 7 at: $pwshPath"
    if (Test-Path $pwshPath) {
        Write-Output "Found pwsh.exe at: $pwshPath"
        try {
            $psVersion = & "$pwshPath" -NoProfile -Command '$PSVersionTable.PSVersion'
            Write-Output "Found PowerShell version: $($psVersion.ToString())"
            if ($psVersion.Major -ge 7) {
                Write-Output "PowerShell 7 or higher is installed."
                return $true
            } else {
                Write-Output "PowerShell version is less than 7: $($psVersion.ToString())."
                return $false
            }
        } catch {
            Write-Output "Error detecting PowerShell version: $_"
            return $false
        }
    } else {
        Write-Output "pwsh.exe not found at $pwshPath"
        return $false
    }
}

# Controleer of PowerShell 7 al is geïnstalleerd
if (Check-PowerShell7Installed) {
    Write-Output "PowerShell 7 is already installed."
} else {
    Write-Output "PowerShell 7 is not installed. Proceeding with installation."
    # Download en installeer PowerShell 7
    $installerUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.2/PowerShell-7.4.2-win-x64.msi"
    $installerPath = "$env:TEMP\PowerShell-7.4.2-win-x64.msi"

    Write-Output "Downloading PowerShell 7 installer from $installerUrl..."
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

    Write-Output "Installing PowerShell 7 from $installerPath..."
    Start-Process msiexec.exe -ArgumentList "/I", $installerPath, "/quiet", "/norestart" -NoNewWindow -Wait

    # Controleer opnieuw of PowerShell 7 nu is geïnstalleerd
    if (Check-PowerShell7Installed) {
        Write-Output "PowerShell 7 installation completed successfully."
    } else {
        Write-Output "PowerShell 7 installation failed."
    }
}
