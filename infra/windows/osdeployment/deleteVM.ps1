# This script deletes a VirtualBox VM and its associated files
# The user is prompted to provide the course name and student number to identify the VM

# Prompt for input
$courseName = Read-Host -Prompt 'Enter the course name'
$studentNumber = Read-Host -Prompt 'Enter the student number'

# Define paths
$baseDir = "C:\Test1\saxion-flex-infra"  # Adjusted base directory
$courseDir = Join-Path -Path $baseDir -ChildPath "Courses\$courseName"
$vhdPath = Join-Path -Path $courseDir -ChildPath "$courseName-$studentNumber-vm1.vhd"
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "$courseName-$studentNumber-vm1"

# Check if VM exists
$vmExists = & $vboxManagePath list vms | Select-String -Pattern $vmName

if ($vmExists) {
    # Unregister and delete the VM
    & $vboxManagePath unregistervm $vmName --delete

    # Remove VHD file
    if (Test-Path $vhdPath) {
        Remove-Item -Path $vhdPath -Force
        Write-Host "Deleted VHD file: $vhdPath"
    } else {
        Write-Host "VHD file not found: $vhdPath"
    }

    # Remove course directory if empty
    if ((Get-ChildItem -Path $courseDir).Count -eq 0) {
        Remove-Item -Path $courseDir -Force
        Write-Host "Deleted empty course directory: $courseDir"
    } else {
        Write-Host "Course directory is not empty: $courseDir"
    }

    Write-Host "VM '$vmName' deleted successfully."
} else {
    Write-Host "VM '$vmName' not found."
}
