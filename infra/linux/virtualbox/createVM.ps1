# Define the VM parameters
$vmName1 = "Test1"
$vmName2 = "Test2"
$vmOSType = "Ubuntu_64" # Choose the OS type you want
$vmBaseFolder = "C:\VirtualMachines"
$vmdkPath = "C:\Users\stefa\Downloads\UbuntuServer_24.04_VM\UbuntuServer_24.04_VM_LinuxVMImages.COM.vmdk" # Path to the VMDK file
$tempFolder = "C:\TempVMs"

# Ensure the temporary directory exists
if (-not (Test-Path -Path $tempFolder)) {
    New-Item -ItemType Directory -Path $tempFolder | Out-Null
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

# Function to copy VMDK and assign a new UUID
function CopyAndPrepareVMDK {
    param (
        [string]$sourceVmdkPath,
        [string]$targetVmdkPath
    )

    Log-Message "Copying VMDK from $sourceVmdkPath to $targetVmdkPath"
    Copy-Item -Path $sourceVmdkPath -Destination $targetVmdkPath

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

# Paths for copied and cloned VMDK files
$tempVmdkPath1 = "$tempFolder\TempDisk1.vmdk"
$tempVmdkPath2 = "$tempFolder\TempDisk2.vmdk"
$clonedVmdkPath1 = "$vmBaseFolder\$vmName1\ClonedDisk1.vmdk"
$clonedVmdkPath2 = "$vmBaseFolder\$vmName2\ClonedDisk2.vmdk"

# Ensure the VM base directories exist
if (-not (Test-Path -Path "$vmBaseFolder\$vmName1")) {
    New-Item -ItemType Directory -Path "$vmBaseFolder\$vmName1" | Out-Null
}
if (-not (Test-Path -Path "$vmBaseFolder\$vmName2")) {
    New-Item -ItemType Directory -Path "$vmBaseFolder\$vmName2" | Out-Null
}

# Copy and prepare the VMDK files
CopyAndPrepareVMDK -sourceVmdkPath $vmdkPath -targetVmdkPath $tempVmdkPath1
CopyAndPrepareVMDK -sourceVmdkPath $vmdkPath -targetVmdkPath $tempVmdkPath2

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
