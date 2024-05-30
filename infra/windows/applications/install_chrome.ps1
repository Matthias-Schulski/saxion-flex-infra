# Specify the URL for the Chrome installer
$chromeUrl = "https://dl.google.com/chrome/install/ChromeStandaloneSetup64.exe"

# Define the path where you want to save the installer
$installerPath = "$PSScriptRoot\ChromeStandaloneSetup64.exe"

# Download the Chrome installer
Invoke-WebRequest -Uri $chromeUrl -OutFile $installerPath

# Install Chrome silently
Start-Process -FilePath $installerPath -ArgumentList "/silent /install" -Verb RunAs
