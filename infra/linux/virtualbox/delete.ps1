# Path to VBoxManage
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$publicFolderPath = "$env:Public\VMNetworkConfigurations"
$createdVmsFilePath = "$env:Public\created_vms.txt"

# Function to stop a VM
function Stop-VM {
    param (
        [string]$vmName
    )
    $vmState = & "$vboxManagePath" showvminfo "$vmName" --machinereadable | Select-String -Pattern "^VMState=" | ForEach-Object { $_.Line.Split("=")[1].Trim('"') }
    if ($vmState -eq "running") {
        Write-Output "Stopping VM: $vmName"
        & "$vboxManagePath" controlvm "$vmName" poweroff
        Start-Sleep -Seconds 10  # Wait for 10 seconds to ensure the VM is fully stopped
    }
}

# Function to remove a VM
function Remove-VM {
    param (
        [string]$vmName
    )
    Stop-VM -vmName $vmName
    Write-Output "Removing VM: $vmName"
    & "$vboxManagePath" unregistervm "$vmName" --delete
    Start-Sleep -Seconds 5  # Wait for 5 seconds to ensure the VM is fully unregistered
}

# Function to remove a network adapter
function Remove-NetworkAdapter {
    param (
        [string]$adapterName
    )
    if ($adapterName -like "VirtualBox Host-Only Ethernet Adapter*") {
        Write-Output "Removing host-only adapter: $adapterName"
        & "$vboxManagePath" hostonlyif remove "$adapterName"
    } elseif ($adapterName -like "NatNetwork_*") {
        Write-Output "Removing NAT network: $adapterName"
        & "$vboxManagePath" natnetwork remove --netname "$adapterName"
    }
}

# Function to remove all configurations for a specific course
function Remove-CourseConfigurations {
    param (
        [string]$configFile
    )

    if (Test-Path $configFile) {
        $configContent = Get-Content -Path $configFile -Raw | ConvertFrom-Json

        # Remove VMs and network adapters
        foreach ($config in $configContent) {
            Remove-VM -vmName $config.VMName
            Remove-NetworkAdapter -adapterName $config.ActualAdapterName
        }

        # Remove VM names from created_vms.txt
        if (Test-Path $createdVmsFilePath) {
            $createdVms = Get-Content -Path $createdVmsFilePath
            $updatedVms = $createdVms | Where-Object { $_ -notmatch "_$($configContent[0].CourseName)" }
            Set-Content -Path $createdVmsFilePath -Value $updatedVms
        }

        # Remove the configuration file
        Remove-Item -Path $configFile -Force
        Write-Output "Removed course configurations from: $configFile"
    } else {
        Write-Output "No configuration file found at path: $configFile"
    }
}

# Retrieve all JSON files from the network configurations folder
$configFiles = Get-ChildItem -Path $publicFolderPath -Filter "NetworkConfig_*.json"

if ($configFiles.Count -eq 0) {
    Write-Output "No configuration files found."
    exit
}

# Prompt the user to select a configuration file to remove
Write-Output "Select the configuration file to remove:"
for ($i = 0; $i -lt $configFiles.Count; $i++) {
    Write-Output "$($i+1). $($configFiles[$i].Name)"
}

$selectedIndex = Read-Host "Enter the number of the configuration file to remove"
if ($selectedIndex -match "^\d+$" -and $selectedIndex -gt 0 -and $selectedIndex -le $configFiles.Count) {
    $selectedConfigFile = $configFiles[$selectedIndex - 1].FullName
    Write-Output "Removing configurations from file: $selectedConfigFile"
    Remove-CourseConfigurations -configFile $selectedConfigFile
} else {
    Write-Output "Invalid selection. Exiting."
}
