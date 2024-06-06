# Define the URL of the 7-Zip installer
$url = "https://www.7-zip.org/a/7z2301-x64.exe" # This URL may change based on the version

# Define the output path for the downloaded installer
$output = "$env:TEMP\7z2301-x64.exe"

# Download the 7-Zip installer
Invoke-WebRequest -Uri $url -OutFile $output

# Install 7-Zip silently
Start-Process -FilePath $output -ArgumentList "/S" -NoNewWindow -Wait

# Remove the installer file after installation
Remove-Item -Path $output
