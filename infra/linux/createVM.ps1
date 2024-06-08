# Define the VM parameters
$vmName = "Test"
$vmOSType = "Ubuntu_64" # Choose the OS type you want
$vmBaseFolder = "C:\VirtualMachines"
$vmdkPath = "C:\Users\stefa\Downloads\Ubuntu_24.04_VM\Ubuntu_24.04_VM_LinuxVMImages.COM.vmdk" # Path to the VMDK file

# Create a new VM
vboxmanage createvm --name $vmName --ostype $vmOSType --register --basefolder $vmBaseFolder

# Set memory and CPU
vboxmanage modifyvm $vmName --memory 2048 --cpus 2

# Attach the VMDK file
vboxmanage storagectl $vmName --name "SATA Controller" --add sata --controller IntelAhci
vboxmanage storageattach $vmName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $vmdkPath

# Set boot order
vboxmanage modifyvm $vmName --boot1 disk --boot2 none --boot3 none --boot4 none

# Set network
vboxmanage modifyvm $vmName --nic1 nat

# Start the VM
vboxmanage startvm $vmName --type gui

Write-Output "Virtual Machine '$vmName' has been created and started successfully."
