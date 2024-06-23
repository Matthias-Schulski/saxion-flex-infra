param (
    [string]$VMName,
    [string]$VHDUrl,
    [string]$OSType,
    [string]$DistroName,
    [int]$MemorySize,
    [int]$CPUs,
    [string]$NetworkTypes,
    [string]$Applications,
    [string]$ConfigureNetworkPath
)

# Tijdelijk wijzigen van de Execution Policy om het uitvoeren van scripts toe te staan
$previousExecutionPolicy = Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Path to VBoxManage
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Log-bestand instellen
$logFilePath = "$env:Public\CreateVM1.log"
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logFilePath -Value $logMessage
}

# Functie om een bestand te downloaden
function Download-File {
    param (
        [string]$url,
        [string]$output
    )
    try {
        $client = New-Object System.Net.WebClient
        $client.DownloadFile($url, $output)
        Log-Message "Downloaded file from $url to $output"
    } catch {
        Log-Message "Failed to download file from $url to $output"
        throw
    }
}

# Function to extract .7z file
function Extract-7z {
    param (
        [string]$sevenZipPath,
        [string]$inputFile,
        [string]$outputFolder
    )
    if (Test-Path $outputFolder) {
        Remove-Item -Recurse -Force $outputFolder
    }
    New-Item -ItemType Directory -Force -Path $outputFolder

    $logFilePath = "$env:Public\7zExtract.log"
    $extractCommand = "& `"$sevenZipPath`" x `"$inputFile`" -o`"$outputFolder`""
    Log-Message "Running extract command: $extractCommand"
    
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $sevenZipPath
    $startInfo.Arguments = "x `"$inputFile`" -o`"$outputFolder`""
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    $output | Add-Content -Path $logFilePath

    $vdiFile = Get-ChildItem -Path $outputFolder -Filter *.vdi -Recurse | Select-Object -First 1
    if (-not $vdiFile) {
        throw "VDI file not found after extraction. Check $logFilePath for details."
    }
    Log-Message "VDI file extracted to $($vdiFile.FullName)"
    return $vdiFile.FullName
}

# Ensure the downloads directory exists
$downloadsPath = "$env:Public\Downloads"
$tempExtractedPath = "$downloadsPath\$VMName"
$vhdLocalPath = "$env:Public\$VMName.7z"
$vhdExtractedPath = "C:\Users\Public\LinuxVMs\$VMName"
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe"

try {
    if (-not (Test-Path $downloadsPath)) {
        New-Item -ItemType Directory -Force -Path $downloadsPath
    }

    # Check if the file already exists
    if (Test-Path $vhdLocalPath) {
        Log-Message "VHD archive file already exists at $vhdLocalPath. Skipping download."
    } else {
        Log-Message "Downloading VHD from $VHDUrl..."
        Download-File $VHDUrl $vhdLocalPath
        Log-Message "Download completed. File size: $((Get-Item $vhdLocalPath).Length) bytes"
    }

    Log-Message "Extracting VHD to $tempExtractedPath..."
    $vdiFilePath = Extract-7z -sevenZipPath $sevenZipPath -inputFile $vhdLocalPath -outputFolder $tempExtractedPath
    Log-Message "Extraction process completed."

    if (-not $vdiFilePath) {
        Log-Message "Extracted VDI file not found in $tempExtractedPath"
        throw "Extraction failed or VDI file not found."
    }
    Log-Message "VDI file path: $vdiFilePath"

    # Ensure $vdiFilePath is a string and correct
    $vdiFilePath = $vdiFilePath -join ""
    $vdiFilePath = $vdiFilePath.Trim()
    $vdiFilePath = $vdiFilePath -replace ".*(C:\\Users\\Public\\Downloads\\.*?\\.*?\.vdi).*", '$1'
    Log-Message "Validated VDI file path: $vdiFilePath"

    # Rename the extracted VDI file to VMName.vdi
    $renamedVDIPath = "$tempExtractedPath\$VMName.vdi"
    Log-Message "Renaming VDI file from $vdiFilePath to $renamedVDIPath"
    Rename-Item -Path $vdiFilePath -NewName "$VMName.vdi"
    Log-Message "VDI file renamed to $renamedVDIPath"

    # Assign a new UUID to the renamed VDI file
    Log-Message "Assigning new UUID to VDI file..."
    & "$vboxManagePath" internalcommands sethduuid "$renamedVDIPath"
    Log-Message "New UUID assigned to $renamedVDIPath"

    # Ensure the target directory exists
    if (-not (Test-Path $vhdExtractedPath)) {
        New-Item -ItemType Directory -Force -Path $vhdExtractedPath
    }

    # Clone the VDI file to the target directory
    $clonedVDIPath = "$vhdExtractedPath\$VMName.vdi"
    Log-Message "Cloning VDI to $clonedVDIPath..."
    & "$vboxManagePath" clonevdi "$renamedVDIPath" "$clonedVDIPath"
    Log-Message "VDI cloned successfully to $clonedVDIPath"

    # Create the VM
    Log-Message "Creating VM..."
    & "$vboxManagePath" createvm --name $VMName --ostype $OSType --register
    Log-Message "VM created successfully."

    # Modify VM settings
    Log-Message "Modifying VM settings..."
    & "$vboxManagePath" modifyvm $VMName --memory $MemorySize --cpus $CPUs --nic1 nat --vram 16 --graphicscontroller vmsvga

    # Assign a unique SSH port for this VM
    $sshPortBase = 2222
    $existingVMs = & "$vboxManagePath" list vms
    $sshPortOffset = ($existingVMs.Count + 1) * 10  # Ensure we get a unique port offset
    $sshPort = $sshPortBase + $sshPortOffset

    & "$vboxManagePath" modifyvm $VMName --natpf1 "SSH,tcp,,$sshPort,,22"
    Log-Message "VM settings modified successfully with SSH port $sshPort."

    # Add storage controller with 1 port
    Log-Message "Adding storage controller..."
    & "$vboxManagePath" storagectl $VMName --name "SATA_Controller" --add sata --controller IntelAhci --portcount 1 --bootable on
    Log-Message "Storage controller added successfully."

    # Attach the cloned VDI to the VM
    Log-Message "Attaching cloned VDI to VM..."
    & "$vboxManagePath" storageattach $VMName --storagectl "SATA_Controller" --port 0 --device 0 --type hdd --medium "$clonedVDIPath"
    & "$vboxManagePath" storageattach $VMName --storagectl "SATA_Controller" --port 1 --device 0 --type hdd --medium "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"    
    Log-Message "Cloned VDI attached successfully."

    # Controleer of het netwerkconfiguratiescript bestaat en lees de inhoud
    if (-not (Test-Path $ConfigureNetworkPath)) {
        throw "Network configuration script not found at $ConfigureNetworkPath"
    }
    $configureNetworkScriptContent = Get-Content -Path $ConfigureNetworkPath -Raw

    # Lees de netwerktypes
    Log-Message "NetworkTypes parameter: $NetworkTypes"

    # Probeer de JSON te parseren
    try {
        $networkTypesArray = $NetworkTypes | ConvertFrom-Json
        Log-Message "Parsed NetworkTypes: $($networkTypesArray | ConvertTo-Json -Compress)"
    } catch {
        Log-Message "Failed to parse NetworkTypes JSON: $_"
        throw "Failed to parse NetworkTypes JSON."
    }

    # Controleer of het parsed JSON een array van objecten is
    if ($null -eq $networkTypesArray -or $networkTypesArray.Count -eq 0) {
        throw "Parsed NetworkTypes is null or empty."
    }

    # Configureer de netwerken
    $nicIndex = 2  # Start from 2 because NIC1 is already configured as NAT
    foreach ($networkType in $networkTypesArray) {
        Log-Message "Configuring network: Type=$($networkType.Type), AdapterName=$($networkType.AdapterName), Network=$($networkType.Network)"
        if ($networkType.Type -eq "bridged") {
            $argsString = "-VMName $VMName -NetworkType $($networkType.Type) -AdapterName $($networkType.AdapterName) -NicIndex $nicIndex"
        } else {
            $argsString = "-VMName $VMName -NetworkType $($networkType.Type) -AdapterName $($networkType.AdapterName) -SubnetNetwork $($networkType.Network) -NicIndex $nicIndex"
        }
        
        Log-Message "Running network configuration with args: $argsString"
        Invoke-Expression "$ConfigureNetworkPath $argsString"
        $nicIndex++
    }

    Log-Message "Starting VM..."
    & "$vboxManagePath" startvm $VMName --type headless
    Log-Message "VM started successfully."

    # Download and execute the post-configuration script
$postConfigScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/linux/virtualbox/linuxNaconfiguratie.ps1"
$postConfigScriptPath = "$downloadsPath\linuxNaconfiguratie.ps1"
Download-File -url $postConfigScriptUrl -output $postConfigScriptPath

# Maak een array met de parameters voor het post-configuratie script
$postConfigArgs = @(
    "-vmname", $VMName,
    "-distroname", $DistroName,
    "-applications", $Applications,
    "-sshport", $sshPort
)

Log-Message "Running post-configuration script with args: $($postConfigArgs -join ' ')"
try {
    & "$postConfigScriptPath" @postConfigArgs
    Log-Message "Post-configuration script executed successfully."
} catch {
    Log-Message "Failed to execute post-configuration script: $($_.Exception.Message)"
    throw
}
}
catch {
    Log-Message "An error occurred: $($_.Exception.Message)"
    throw
}
Log-Message "Script execution completed successfully."

# Herstel de oorspronkelijke Execution Policy
Set-ExecutionPolicy -ExecutionPolicy $previousExecutionPolicy -Scope Process -Force
echo test
