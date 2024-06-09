# Functie om te controleren of PowerShell 7 al is geïnstalleerd
function Check-PowerShell7Installed {
    try {
        $installedPrograms = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "PowerShell*" }
        foreach ($program in $installedPrograms) {
            Write-Output "Found installed program: $($program.Name) version $($program.Version)"
            if ($program.Name -match "PowerShell" -and [version]$program.Version -ge [version]"7.0.0") {
                Write-Output "PowerShell 7 or higher is installed."
                return $true
            }
        }
        Write-Output "PowerShell 7 is not installed."
        return $false
    } catch {
        Write-Output "Error detecting installed programs: $_"
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

