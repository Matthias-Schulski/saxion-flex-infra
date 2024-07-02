# Path to VBoxManage
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$publicFolderPath = "$env:Public\VMNetworkConfigurations"
$createdVmsFilePath = "$env:Public\created_vms.txt"
$vmDownloadPath = "C:\Users\Public\Downloads"

# Function to stop a VM
function Stop-VM {
    param (
        [string]$vmName
    )
    try {
        $vmState = & "$vboxManagePath" showvminfo "$vmName" --machinereadable | Select-String -Pattern "^VMState=" | ForEach-Object { $_.Line.Split("=")[1].Trim('"') }
        if ($vmState -eq "running") {
            & "$vboxManagePath" controlvm "$vmName" poweroff *> $null 2>&1
            Start-Sleep -Seconds 10  # Wait for 10 seconds to ensure the VM is fully stopped
        }
    } catch {
        Write-Host "Error stopping VM ${vmName}: $_" -ForegroundColor Red
    }
}

# Function to remove a VM
function Remove-VM {
    param (
        [string]$vmName
    )
    try {
        Stop-VM -vmName $vmName
        & "$vboxManagePath" unregistervm "$vmName" --delete *> $null 2>&1
        Start-Sleep -Seconds 5  # Wait for 5 seconds to ensure the VM is fully unregistered
    } catch {
        Write-Host "Error removing VM ${vmName}: $_" -ForegroundColor Red
    }
}

# Function to remove a network adapter
function Remove-NetworkAdapter {
    param (
        [string]$adapterName
    )
    try {
        if ($adapterName -like "VirtualBox Host-Only Ethernet Adapter*") {
            & "$vboxManagePath" hostonlyif remove "$adapterName" *> $null 2>&1
        } elseif ($adapterName -like "NatNetwork_*") {
            & "$vboxManagePath" natnetwork remove --netname "$adapterName" *> $null 2>&1
        }
    } catch {
        Write-Host "Error removing network adapter ${adapterName}: $_" -ForegroundColor Red
    }
}

# Function to remove hard disks associated with a VM
function Remove-VMHardDisks {
    param (
        [string]$vmName
    )
    try {
        $vmDiskFilePath = "$vmDownloadPath\$vmName\$vmName.vdi"

        # Check if the VDI file exists in the download path and remove it
        if (Test-Path $vmDiskFilePath) {
            & "$vboxManagePath" closemedium disk "$vmDiskFilePath" --delete *> $null 2>&1
        }

        # Remove the download folder if it exists
        $vmDownloadFolderPath = "$vmDownloadPath\$vmName"
        if (Test-Path $vmDownloadFolderPath) {
            Remove-Item -Path $vmDownloadFolderPath -Recurse -Force *> $null 2>&1
        }
    } catch {
        Write-Host "Error removing hard disks for VM ${vmName}: $_" -ForegroundColor Red
    }
}

# Function to remove all configurations for a specific course
function Remove-CourseConfigurations {
    param (
        [string]$configFile,
        [string]$courseName
    )

    try {
        if (Test-Path $configFile) {
            $configContent = Get-Content -Path $configFile -Raw | ConvertFrom-Json

            # Remove VMs, network adapters, and hard disks
            foreach ($config in $configContent) {
                Remove-VM -vmName $config.VMName
                Remove-NetworkAdapter -adapterName $config.ActualAdapterName
                Remove-VMHardDisks -vmName $config.VMName
            }

            # Check if there are any NAT networks to remove
            $natNetworksToRemove = $configContent | Where-Object { $_.ActualAdapterName -like "NatNetwork_*" }
            foreach ($natNetwork in $natNetworksToRemove) {
                Remove-NetworkAdapter -adapterName $natNetwork.ActualAdapterName
            }

            # Remove VM names from created_vms.txt
            if (Test-Path $createdVmsFilePath) {
                $createdVms = Get-Content -Path $createdVmsFilePath
                $updatedVms = $createdVms | Where-Object { $_ -notmatch "_$courseName" }
                Set-Content -Path $createdVmsFilePath -Value $updatedVms *> $null 2>&1
            }

            # Remove the configuration file
            Remove-Item -Path $configFile -Force *> $null 2>&1
        }

        # Additionally remove any VMs from created_vms.txt with the specified course name
        if (Test-Path $createdVmsFilePath) {
            $createdVms = Get-Content -Path $createdVmsFilePath
            $vmsToRemove = $createdVms | Where-Object { $_ -match "^$courseName" }
            foreach ($vmName in $vmsToRemove) {
                Remove-VM -vmName $vmName
                Remove-VMHardDisks -vmName $vmName
            }
            $updatedVms = $createdVms | Where-Object { $_ -notmatch "^$courseName" }
            Set-Content -Path $createdVmsFilePath -Value $updatedVms *> $null 2>&1
        }
    } catch {
        Write-Host "Error removing course configurations for ${configFile}: $_" -ForegroundColor Red
    }
}

# Retrieve all JSON files from the network configurations folder
$configFiles = Get-ChildItem -Path $publicFolderPath -Filter "NetworkConfig_*.json"

if ($configFiles.Count -eq 0) {
    exit
}

# Get course names from the configuration files
$courseNames = $configFiles | ForEach-Object { ($_.BaseName -split '_', 2)[1] }

# Prompt the user to select a configuration file to remove
$courseNames | ForEach-Object -Begin { Write-Host "Select the configuration file to remove:" -ForegroundColor White } -Process {
    Write-Host "$($courseNames.IndexOf($_) + 1). $($_)" -ForegroundColor Blue
}

$selectedIndex = Read-Host "Enter the number of the configuration file to remove"
if ($selectedIndex -match "^\d+$" -and $selectedIndex -gt 0 -and $selectedIndex -le $courseNames.Count) {
    $selectedConfigFile = $configFiles[$selectedIndex - 1].FullName
    $selectedCourseName = $courseNames[$selectedIndex - 1]
    Write-Host "Removing Course Files and VM's..." -ForegroundColor White
    Remove-CourseConfigurations -configFile $selectedConfigFile -courseName $selectedCourseName
    Write-Host "Course files and VM's removed successfully." -ForegroundColor Green
} else {
    Write-Host "Invalid selection. Exiting."
}
