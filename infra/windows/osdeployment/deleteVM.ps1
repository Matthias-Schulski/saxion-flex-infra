param (
    [string]$CourseName
)

# Prompt the user for the course name if not provided
if (-not $CourseName) {
    $CourseName = Read-Host "Please enter the course name to delete (e.g., course2.json)"
}

# Define paths and URLs
$baseDir = "C:\SAX-FLEX-INFRA"
$courseJsonUrl = "https://raw.githubusercontent.com/Matthias-Schulski/saxion-flex-infra/main/courses/$CourseName"

# Fetch the JSON data
try {
    $courseData = Invoke-RestMethod -Uri $courseJsonUrl -Method Get -ErrorAction Stop
}
catch {
    Write-Error "Failed to retrieve JSON data. Please check the course name and URL."
    exit
}

# Define VBoxManage path
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Function to stop a VM
function Stop-VM {
    param (
        [string]$vmName
    )
    $vmState = & "$vboxManagePath" showvminfo "$vmName" --machinereadable | Select-String -Pattern "^VMState=" | ForEach-Object { $_.Line.Split("=")[1].Trim('"') }
    if ($vmState -eq "running") {
        & "$vboxManagePath" controlvm "$vmName" poweroff *> $null 2>&1
        Start-Sleep -Seconds 10  # Wait for 10 seconds to ensure the VM is fully stopped
    }
}

# Function to remove a VM
function Remove-VM {
    param (
        [string]$vmName
    )
    Stop-VM -vmName $vmName
    & "$vboxManagePath" unregistervm "$vmName" --delete *> $null 2>&1
    Start-Sleep -Seconds 5  # Wait for 5 seconds to ensure the VM is fully unregistered
}

# Function to remove hard disks associated with a VM
function Remove-VMHardDisks {
    param (
        [string]$vhdPath
    )

    # Check if the VHD file exists and remove it
    if (Test-Path $vhdPath) {
        & "$vboxManagePath" closemedium disk "$vhdPath" --delete *> $null 2>&1
        Remove-Item -Path $vhdPath -Force *> $null 2>&1
        Write-Host "Deleted VHD file: $vhdPath"
    } else {
        Write-Host "VHD file not found: $vhdPath"
    }
}

# Process each VM in the JSON
foreach ($vm in $courseData.VMs) {
    if ($vm.Platform -eq "Windows") {
        # VM details from JSON
        $vmName = $vm.VMName
        $namingVariable = "$vmName-$CourseName"

        # Define paths
        $courseDir = Join-Path -Path $baseDir -ChildPath "Courses\$CourseName"
        $vhdPath = Join-Path -Path $courseDir -ChildPath "VHD-$namingVariable.vhd"  # Standardized VHD naming

        # Remove VM and associated files
        $fullVmName = "VM-$namingVariable"
        Write-Host "Removing VM '$fullVmName'..."
        Remove-VM -vmName $fullVmName
        Remove-VMHardDisks -vhdPath $vhdPath

        # Remove course directory if empty
        if ((Get-ChildItem -Path $courseDir).Count -eq 0) {
            Remove-Item -Path $courseDir -Force
            Write-Host "Deleted empty course directory: $courseDir"
        } else {
            Write-Host "Course directory is not empty: $courseDir"
        }

        Write-Host "VM '$fullVmName' and associated files deleted successfully."
    }
}

Write-Host "All VMs have been processed for deletion successfully."
