# Set the variable $Path to the location of the temporary folder
$Path = $env:TEMP; 

# Set the variable $Installer to the name of the installer file
$Installer = "chrome_installer.exe"; 

# Download the Chrome installer from the specified URL and save it in the temporary folder with the specified name
Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile $Path\$Installer; 

# Start the installer with silent installation and elevated permissions
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait; 

# Delete the installer file after installation is complete
Remove-Item -Path $Path\$Installer
