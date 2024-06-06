# URL van de Firefox installer
$url = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"

# Locatie waar de Firefox installer wordt gedownload
$output = "$env:TEMP\FirefoxInstaller.exe"

# Download de Firefox installer van de opgegeven URL
Invoke-WebRequest -Uri $url -OutFile $output

# Start de installatie van Firefox
Start-Process -FilePath $output -ArgumentList "/S" -Wait

# Verwijder de gedownloade installer na installatie
Remove-Item -Path $output
