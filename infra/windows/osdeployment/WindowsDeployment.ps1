param (
    [string]$CourseName
)

# Check if CourseName is provided
if (-not $CourseName) {
    Write-Host "Error: CourseName is required."
    $CourseName = "course2.json"
}

# Define paths and URLs
$baseDir = "C:\SAX-FLEX-INFRA"
$courseJsonUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/course2.json"

# Construct the course JSON URL
# $courseJsonUrl = "$courseBaseUrl$CourseName.json"

# Fetch the JSON data
try {
    $courseData = Invoke-RestMethod -Uri $courseJsonUrl -Method Get -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve JSON data. Please check the course name and URL."
    exit
}

# Create the course directory
$courseDir = Join-Path -Path $baseDir -ChildPath "Courses\$CourseName"
New-Item -ItemType Directory -Force -Path $courseDir

# Process each VM in the JSON
foreach ($vm in $courseData.VMs) {
    if ($vm.Platform -eq "Windows") {
        # VM details from JSON
        $vmName = $vm.VMName
        $cpu = $vm.VMCpuCount
        $ram = $vm.VMMemorySize

        # Define paths
        $vhdPath = Join-Path -Path $baseDir -ChildPath 'BASE-FILES\Windows server 2022.vhd'
        $newVhdPath = Join-Path -Path $courseDir -ChildPath "VHD-$vmName-$CourseName.vhd"  # Standardized VHD naming
        $unattendedPath = Join-Path -Path $baseDir -ChildPath 'BASE-FILES\unattend.xml'
        $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

        # Copy and rename VHD
        Copy-Item -Path $vhdPath -Destination $newVhdPath

        # Mount the VHD
        $DriveLetter = (Mount-VHD -Path $newVhdPath -PassThru | Get-Disk | Get-Partition | Get-Volume).DriveLetter

        # Create Panther directory
        New-Item -ItemType Directory -Force -Path "$($DriveLetter):\Windows\Panther"

        # Create Applications directory
        $applicationDirectory = "$($DriveLetter):\Windows\Setup\Applications"
        if (-Not (Test-Path $applicationDirectory)) {
            New-Item -ItemType Directory -Path $applicationDirectory
        }

        # Save VMApplications to a JSON file
        $vmApplicationsJson = $vm.VMApplications | ConvertTo-Json -Depth 1
        $jsonFilePath = "$applicationDirectory\VMApplications.json"
        Set-Content -Path $jsonFilePath -Value $vmApplicationsJson

        # Download the install script
        $installScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/windows/applications/install_applications.ps1"
        $installScriptPath = "$applicationDirectory\install_applications.ps1"
        Invoke-WebRequest -Uri $installScriptUrl -OutFile $installScriptPath

        Write-Host "VMApplications JSON and install script have been downloaded and saved to $applicationDirectory"

        # Copy and edit Autounattend.xml (assuming $studentName and $studentNumber are defined elsewhere)
        $unattendedContent = Get-Content -Path $unattendedPath -Raw
        $unattendedContent = $unattendedContent.Replace('var-username', $studentName).Replace('var-pc-name', $studentNumber)
        Set-Content -Path "$($DriveLetter):\Windows\Panther\unattend.xml" -Value $unattendedContent

        # Dismount the VHD
        Dismount-DiskImage -ImagePath $newVhdPath

        # Change the UUID
        & $vboxManagePath internalcommands sethduuid $newVhdPath

        # Create a VM in VirtualBox
        & $vboxManagePath createvm --name "$CourseName-$vmName" --ostype="Windows2022_64" --register
        & $vboxManagePath modifyvm "$CourseName-$vmName" --cpus $cpu --memory $ram
        & $vboxManagePath storagectl "$CourseName-$vmName" --name "SATA Controller" --add sata --controller IntelAhci
        & $vboxManagePath storageattach "$CourseName-$vmName" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $newVhdPath

        Write-Host "VM $vmName has been created and configured."
    }
}

Write-Host "All VMs have been processed successfully."
