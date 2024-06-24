param (
    [string]$CourseName
)


$studentNamePath = "C:\Users\Public\student_name.txt"
$studentNumberPath = "C:\Users\Public\student_number.txt"

$baseDir = "C:\SAX-FLEX-INFRA"
$subFolderPath = "C:\SAX-FLEX-INFRA\BASE-FILES"
$courseJsonUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/course2.json"

# Check if CourseName is provided
if (-not $CourseName) {
    Write-Host "Error: CourseName is required."
    $CourseName = "course2.json"
}

# Read student name and number from file

if (-not (Test-Path -Path $studentNamePath)) {
    Write-Host "Error: $studentNamePath does not exist."
    exit
}
if (-not (Test-Path -Path $studentNumberPath)) {
    Write-Host "Error: $studentNumberPath does not exist."
    exit
}

$studentName = Get-Content -Path $studentNamePath -Raw
$studentNumber = Get-Content -Path $studentNumberPath -Raw

function Check-Environment {
    # Check if the base folder exists
    if (-not (Test-Path -Path $baseDir)) {
        # If it doesn't exist, create it
        New-Item -Path $baseDir -ItemType Directory
        Write-Output "Created folder: $baseFolderPath"
    } else {
        Write-Output "Folder already exists: $baseDir"
    }

    # Check if the subfolder exists
    if (-not (Test-Path -Path $subFolderPath)) {
        # If it doesn't exist, create it
        New-Item -Path $subFolderPath -ItemType Directory
        Write-Output "Created folder: $subFolderPath"
    } else {
        Write-Output "Folder already exists: $subFolderPath"
    }
}

# Define the function to check the VHD file

# Define the function to download the VHD file
function Download-VHD {
    param (
        [string]$OSType,
        [string]$DownloadPath
    )

    # Define the download destination
    $destinationPath = "C:\SAX-FLEX-INFRA\BASE-FILES\$OSType.vhd"

    # Download the VHD file
    Write-Output "Downloading VHD file for $OSType from $DownloadPath..."
    Invoke-WebRequest -Uri $DownloadPath -OutFile $destinationPath
    Write-Output "Download complete. File saved to $destinationPath."
}

# Define the function to check the VHD file
function Check-VHDFile {
    param (
        [string]$OSVersion
    )

    # Define the VHD file path
    $vhdFilePath = "C:\SAX-FLEX-INFRA\BASE-FILES\$($OSVersion).vhd"

    # Check if the VHD file exists
    if (Test-Path -Path $vhdFilePath) {
        Write-Output "VHD file exists: $vhdFilePath"
    } else {
        Write-Output "VHD file does not exist: $vhdFilePath"
        # Download the JSON file containing the VHD download links
        $jsonUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/list_of_vhdfiles.JSON"
        $jsonFile = Invoke-WebRequest -Uri $jsonUrl -UseBasicParsing
        $vhds = $jsonFile.Content | ConvertFrom-Json

        # Find the download path for the specified OSType
        $vhdInfo = $vhds | Where-Object { $_.OSType -eq $OSVersion }

        if ($vhdInfo -ne $null) {
            # Call the Download-VHD function to download the VHD file
            Download-VHD -OSType $OSVersion -DownloadPath $vhdInfo.DownloadPath
        } else {
            Write-Output "No download link found for OSType: $($OSVersion)"
        }
    }
}

function Check-unattend.xml {


    # Define the XML file path
    $unattendFilePath = "C:\SAX-FLEX-INFRA\BASE-FILES\unattend.xml"

    # Check if the XML file exists
    if (Test-Path -Path $unattendFilePath) {
        Write-Output "Unattend file exists: $unattendFilePath"
    } else {

    # Download the unattend file
    Write-Output "Downloading unattend file"
    $DownloadPath = "https://raw.githubusercontent.com/saxion-flex-infra/blob/main/infra/windows/osdeployment/unattend.xml"
    Invoke-WebRequest -Uri $DownloadPath -OutFile $unattendFilePath
    Write-Output "Download complete. File saved to $unattendFilePath."
    }
}

# Fetch the JSON data
try {
    $courseData = Invoke-RestMethod -Uri $courseJsonUrl -Method Get -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve JSON data. Please check the course name and URL."
    exit
}
# Call the function to perform the environment check
Check-Environment

# Define the function to perform the environment check


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

        $varLanguage = "$($courseData.EnvironmentVariables.Language)"
        $varKeyboard = "$($courseData.EnvironmentVariables.KeyboardLayout)"
        $namingVariable = "$($courseData.EnvironmentVariables.NamingScheme)"

        Check-VHDFile($vm.OSVersion)

        # Define paths
        $vhdPath = Join-Path -Path $baseDir -ChildPath "BASE-FILES\$($vm.OSVersion).vhd"
        $newVhdPath = Join-Path -Path $courseDir -ChildPath "VHD-$namingVariable.vhd"  # Standardized VHD naming
        $unattendedPath = Join-Path -Path $baseDir -ChildPath 'BASE-FILES\unattend.xml'
        $vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
        $vboxGuestAdditionsPath = "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"  # Path to VBoxGuestAdditions.iso

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

        # Download and save role scripts
        foreach ($role in $vm.Roles) {
            $roleScriptUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/infra/windows/roles/$($role -replace ' ', '_').ps1"
            $roleScriptPath = "$applicationDirectory\$($role -replace ' ', '_').ps1"
            Invoke-WebRequest -Uri $roleScriptUrl -OutFile $roleScriptPath
            Write-Host "Role script for $role has been downloaded and saved to $applicationDirectory"
        }

        # Copy and edit Autounattend.xml (assuming $studentName and $studentNumber are defined elsewhere)
        $unattendedContent = Get-Content -Path $unattendedPath -Raw
        $unattendedContent = $unattendedContent.Replace('var-username', $studentName).Replace('var-pc-name', $studentNumber).Replace('varLanguage', $varLanguage).Replace('varKeyboard', $varKeyboard)
        Set-Content -Path "$($DriveLetter):\Windows\Panther\unattend.xml" -Value $unattendedContent

        # Dismount the VHD
        Dismount-DiskImage -ImagePath $newVhdPath

        # Change the UUID
        & $vboxManagePath internalcommands sethduuid $newVhdPath

        # Create a VM in VirtualBox
        $vmFullName = "VM-$namingVariable"
        & $vboxManagePath createvm --name "$vmFullName" --ostype="Windows2022_64" --register
        & $vboxManagePath modifyvm "$vmFullName" --cpus $cpu --memory $ram
        & $vboxManagePath storagectl "$vmFullName" --name "SATA-Controller-$namingVariable" --add sata --controller IntelAhci
        & $vboxManagePath storageattach "$vmFullName" --storagectl "SATA-Controller-$namingVariable" --port 0 --device 0 --type hdd --medium $newVhdPath

        # Attach the VirtualBox Guest Additions ISO
        & $vboxManagePath storageattach "$vmFullName" --storagectl "SATA-Controller-$namingVariable" --port 1 --device 0 --type dvddrive --medium $vboxGuestAdditionsPath

        Write-Host "VM $vmName has been created and configured."
    }
}

Write-Host "All VMs have been processed successfully."
