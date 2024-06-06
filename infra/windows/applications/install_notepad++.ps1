# URL van de Notepad++ installer
$url = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.2.1/npp.8.2.1.Installer.exe"

# Locatie waar de Notepad++ installer wordt gedownload
$output = "$env:TEMP\npp_installer.exe"

# Download de Notepad++ installer van de opgegeven URL
Invoke-WebRequest -Uri $url -OutFile $output

# Start de installatie van Notepad++
Start-Process -FilePath $output -ArgumentList "/S" -Wait

# Verwijder de gedownloade installer na installatie
Remove-Item -Path $output
