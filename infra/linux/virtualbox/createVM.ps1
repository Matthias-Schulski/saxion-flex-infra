# Define the VM parameters
$vmName1 = "Test1"
$vmName2 = "Test2"
$vmOSType = "Ubuntu_64" 
$vmBaseFolder = "C:\VirtualMachines"
$vhdUrl1 = "https://dlconusc1.linuxvmimages.com/046389e06777452db2ccf9a32efa3760:vmware/U/24.04/UbuntuServer_24.04_VM.7z"
$vhdUrl2 = "https://dlconusc1.linuxvmimages.com/046389e06777452db2ccf9a32efa3760:vmware/U/24.04/UbuntuServer_24.04_VM.7z"
$downloadFolder = "C:\TempVMs"
$sevenZipPath = "C:\Program Files\7-Zip\7z.exe" # Path to 7-Zip executable

# Ensure the download directory exists
if (-not (Test-Path -Path $downloadFolder)) {
    New-Item -ItemType Directory -Path $downloadFolder | Out-Null
}

# Function to log messages
function Log-Message {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Write-Output $logMessage
    Add-Content -Path "$env:Public\CreateVM.log" -Value $logMessage
}

# Function to download VHD files
function DownloadVHD {
    param (
        [string]$vhdUrl,
        [string]$downloadPath
    )

    Log-Message "Downloading VHD from $vhdUrl to $downloadPath"
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($vhdUrl, $downloadPath)
        Log-Message "Download complete: $downloadPath"
    } catch {
        Log-Message "Error downloading $vhdUrl: $(${Error[0].Exception.Message})"
        throw $_
    }
}

# Function to extract VMDK from a 7z file
function ExtractVMDK {
    param (
        [string]$sevenZipPath,
        [string]$archivePath,
        [string]$extractPath
    )

    if (-not (Test-Path -Path $extractPath)) {
        New-Item -ItemType Directory -Path $extractPath | Out-Null
    }

    Log-Message "Extracting VMDK from $archivePath to $extractPath"
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $sevenZipPath
    $startInfo.Arguments = "x `"$archivePath`" -o`"$extractPath`" -y"
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $output = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    Log-Message "Extraction output: $output"

    $vmdkFile = Get-ChildItem -Path $extractPath -Filter *.vmdk -Recurse | Select-Object -First 1
    if (-not $vmdkFile) {
        throw "VMDK file not found after extraction."
    }
    return $vmdkFile.FullName
}

# Function to copy VMDK and assign a new UUID
function CopyAndPrepareVMDK {
    param (
        [string]$sourceVmdkPath,
        [string]$targetVmdkPath
    )

    Log-Message "Copying VMDK from $sourceVmdkPath to $targetVmdkPath"
    Copy-Item -Path $sourceVmdkPath -Destination $targetVmdkPath -Force

    Log-Message "Assigning new UUID to $targetVmdkPath"
    vboxmanage internalcommands sethduuid $targetVmdkPath | Out-Null
}

# Function to clone the VMDK file
function CloneVMDK {
    param (
        [string]$sourceVmdkPath,
        [string]$clonedVmdkPath
    )

    Log-Message "Cloning VMDK from $sourceVmdkPath to $clonedVmdkPath"
    vboxmanage clonemedium disk $sourceVmdkPath $clonedVmdkPath --format VMDK --variant Standard | Out-Null
}

# Function to create and configure a VM
function CreateAndConfigureVM {
    param (
        [string]$vmName,
        [string]$vmOSType,
        [string]$vmBaseFolder,
        [string]$vmdkPath
    )

    Log-Message "Creating VM: $vmName"
    vboxmanage createvm --name $vmName --ostype $vmOSType --register --basefolder $vmBaseFolder | Out-Null

    Log-Message "Setting memory and CPU for VM: $vmName"
    vboxmanage modifyvm $vmName --memory 2048 --cpus 2 | Out-Null

    Log-Message "Adding storage controller for VM: $vmName"
    vboxmanage storagectl $vmName --name "SATA Controller" --add sata --controller IntelAhci | Out-Null

    Log-Message "Attaching VMDK file to VM: $vmName"
    vboxmanage storageattach $vmName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $vmdkPath | Out-Null

    Log-Message "Setting boot order for VM: $vmName"
    vboxmanage modifyvm $vmName --boot1 disk --boot2 none --boot3 none --boot4 none | Out-Null

    Log-Message "Setting network for VM: $vmName"
    vboxmanage modifyvm $vmName --nic1 nat | Out-Null
}

# Paths for downloaded, extracted, and cloned VMDK files
$downloadedArchivePath1 = Join-Path -Path $downloadFolder -ChildPath "DownloadedArchive1.7z"
$downloadedArchivePath2 = Join-Path -Path $downloadFolder -ChildPath "DownloadedArchive2.7z"
$extractedVmdkPath1 = Join-Path -Path $downloadFolder -ChildPath "ExtractedDisk1"
$extractedVmdkPath2 = Join-Path -Path $downloadFolder -ChildPath "ExtractedDisk2"
$tempVmdkPath1 = Join-Path -Path $downloadFolder -ChildPath "TempDisk1.vmdk"
$tempVmdkPath2 = Join-Path -Path $downloadFolder -ChildPath "TempDisk2.vmdk"
$clonedVmdkPath1 = Join-Path -Path $vmBaseFolder -ChildPath "$vmName1\ClonedDisk1.vmdk"
$clonedVmdkPath2 = Join-Path -Path $vmBaseFolder -ChildPath "$vmName2\ClonedDisk2.vmdk"

# Ensure the VM base directories exist
if (-not (Test-Path -Path (Join-Path -Path $vmBaseFolder -ChildPath $vmName1))) {
    New-Item -ItemType Directory -Path (Join-Path -Path $vmBaseFolder -ChildPath $vmName1) | Out-Null
}
if (-not (Test-Path -Path (Join-Path -Path $vmBaseFolder -ChildPath $vmName2))) {
    New-Item -ItemType Directory -Path (Join-Path -Path $vmBaseFolder -ChildPath $vmName2) | Out-Null
}

# Download the VHD files
DownloadVHD -vhdUrl $vhdUrl1 -downloadPath $downloadedArchivePath1
DownloadVHD -vhdUrl $vhdUrl2 -downloadPath $downloadedArchivePath2

# Extract the VMDK files from the downloaded archives
$extractedVmdkFile1 = ExtractVMDK -sevenZipPath $sevenZipPath -archivePath $downloadedArchivePath1 -extractPath $extractedVmdkPath1
$extractedVmdkFile2 = ExtractVMDK -sevenZipPath $sevenZipPath -archivePath $downloadedArchivePath2 -extractPath $extractedVmdkPath2

# Ensure valid paths for extracted VMDK files
if (-not (Test-Path -Path $extractedVmdkFile1)) {
    throw "Extracted VMDK file not found at $extractedVmdkFile1"
}
if (-not (Test-Path -Path $extractedVmdkFile2)) {
    throw "Extracted VMDK file not found at $extractedVmdkFile2"
}

# Copy and prepare the VMDK files
CopyAndPrepareVMDK -sourceVmdkPath $extractedVmdkFile1 -targetVmdkPath $tempVmdkPath1
CopyAndPrepareVMDK -sourceVmdkPath $extractedVmdkFile2 -targetVmdkPath $tempVmdkPath2

# Clone the prepared VMDK files to the final locations
CloneVMDK -sourceVmdkPath $tempVmdkPath1 -clonedVmdkPath $clonedVmdkPath1
CloneVMDK -sourceVmdkPath $tempVmdkPath2 -clonedVmdkPath $clonedVmdkPath2

# Create and configure the first VM
CreateAndConfigureVM -vmName $vmName1 -vmOSType $vmOSType -vmBaseFolder $vmBaseFolder -vmdkPath $clonedVmdkPath1

# Create and configure the second VM
CreateAndConfigureVM -vmName $vmName2 -vmOSType $vmOSType -vmBaseFolder $vmBaseFolder -vmdkPath $clonedVmdkPath2

# Start the VMs
Log-Message "Starting VM: $vmName1"
vboxmanage startvm $vmName1 --type gui | Out-Null

Log-Message "Starting VM: $vmName2"
vboxmanage startvm $vmName2 --type gui | Out-Null

Write-Output "Virtual Machines '$vmName1' and '$vmName2' have been created and started successfully."
