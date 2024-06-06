# Controleer of Chocolatey is geïnstalleerd
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey is niet geïnstalleerd. Het wordt nu geïnstalleerd..."
    
    # Installeer Chocolatey
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    
    # Controleer opnieuw of Chocolatey is geïnstalleerd
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Er is een probleem opgetreden bij het installeren van Chocolatey."
        exit
    }
}

# Installeer Nano met Chocolatey
choco install nano -y
