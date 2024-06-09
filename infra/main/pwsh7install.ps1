# Functie om te controleren of PowerShell 7 al is geïnstalleerd
function Check-PowerShell7Installed {
    try {
        $pwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
        if ($pwshPath) {
            Write-Output "Found pwsh at: $pwshPath"
            $psVersionOutput = & "pwsh" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
            Write-Output "pwsh version output: $psVersionOutput"
            $psVersion = [version]$psVersionOutput
            if ($psVersion.Major -ge 7) {
                Write-Output "PowerShell 7 or higher is installed."
                return $true
            } else {
                Write-Output "PowerShell version is less than 7: $psVersion"
                return $false
            }
        } else {
            Write-Output "pwsh command not found."
            return $false
        }
    } catch {
        Write-Output "Error detecting PowerShell 7: $_"
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
echo trest
