param (
    [string]$CourseName
)

# Check if CourseName is provided
if (-not $CourseName) {
    Write-Host "Error: CourseName is required."
    exit
}

# Read student name and number from files
$studentNamePath = "C:\Users\Public\student_name.txt"
$studentNumberPath = "C:\Users\Public\student_number.txt"

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

# Ask for input
$cpu = Read-Host -Prompt 'Enter the number of CPUs'
$ram = Read-Host -Prompt 'Enter the amount of RAM in MB'

# Define paths
$baseDir = "C:\SAX-FLEX-INFRA"
$courseDir = Join-Path -Path $baseDir -ChildPath "Courses\$CourseName"
$vhdPath = Join-Path -Path $baseDir -ChildPath 'BASE-FILES\Windows server 2022.vhd'
$githubCourseFile = "https://github.com/Matthias-Schulski/saxion-flex-infra/blob/main/courses/$CourseName"
$newVhdPath = Join-Path -Path $courseDir -ChildPath "$CourseName-$studentNumber-vm1.vhd"
$unattendedPath = Join-Path -Path $baseDir -ChildPath 'BASE-FILES\unattend.xml'
$vboxManagePath = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"

# Create course directory
New-Item -ItemType Directory -Force -Path $courseDir

# Copy and rename VHD
Copy-Item -Path $vhdPath -Destination $newVhdPath

# Mount the VHD
$DriveLetter = (Mount-VHD -Path $newVhdPath -PassThru | Get-Disk | Get-Partition | Get-Volume).DriveLetter

# Create Panther directory
New-Item -ItemType Directory -Force -Path "$($DriveLetter):\Windows\Panther"

# Copy and edit Autounattend.xml
$unattendedContent = Get-Content -Path $unattendedPath -Raw
$unattendedContent = $unattendedContent.Replace('var-username', $studentName).Replace('var-pc-name', $studentNumber)
Set-Content -Path "$($DriveLetter):\Windows\Panther\unattend.xml" -Value $unattendedContent

# Dismount the VHD
Dismount-DiskImage -ImagePath $newVhdPath

# Change the UUID
& $vboxManagePath internalcommands sethduuid $newVhdPath

# Create a VM
& $vboxManagePath createvm --name "$CourseName-$studentNumber-vm1" --ostype="Windows2022_64" --register
& $vboxManagePath modifyvm "$CourseName-$studentNumber-vm1" --cpus $cpu --memory $ram
& $vboxManagePath storagectl "$CourseName-$studentNumber-vm1" --name "SATA Controller" --add sata --controller IntelAhci
& $vboxManagePath storageattach "$CourseName-$studentNumber-vm1" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $newVhdPath
