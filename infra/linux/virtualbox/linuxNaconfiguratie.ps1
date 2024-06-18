#### SITUATIE: VMS GEMAAKT
#### NA CONFIGURATIE MOET GEDAAN WORDEN
$jsonfilePath = "C:\Users\vlind\VirtualBox VMs\course3.json"            #MOET EEN TEKST BESTAND WORDEN MET ALLE GEMAAKTE VMS
$jsoncontent = Get-Content $jsonfilePath -Raw | ConvertFrom-Json        #ZAL WEGGAAN

### PARAMETERS DIE EIGENLIJK UIT VORIGE SCRIPT MOETEN KOMEN
#param (
$username = "ubuntu"         #DEFAULT USER
$password = "ubuntu"         #DEFAULT WACHTWOORD
$hostname = "ubuntu"    #Wordt misschien nog geleverd uit vorige script??
#)

###### HOORT TE KOMEN UIT VORIGE SCRIPT ENKEL HIER VOOR PERSOONLIJKE TEST
#foreach ($VM in $jsoncontent.VMs)
#{
#    $counter++
#    Write-Host "VM $counter naam: $($VM.VMName)"
#    Write-Host "VM $counter RAM: $($VM.VMMemorysize)"
#    Write-Host "VM $counter Netwerk: $($VM.VMNetworktype)"
#    Write-Host "VM $counter Portforwarding: $($VM.portforwarding.hostport) --> $($VM.portforwarding.vmport)"
#    mkdir $($VM.VMname)
#    
#    Write-Host "VDI-bestand overkopiëren naar directory" -ForegroundColor Yellow
#    Copy-Item -Path "C:\Users\vlind\VirtualBox VMs\EXTRA VDI\UbuntuSV24_04.vdi" -Destination "C:\Users\vlind\VirtualBox VMs\$($VM.VMname)"
#    VBoxManage internalcommands sethduuid "C:\Users\vlind\VirtualBox VMs\$($VM.VMname)\UbuntuSV24_04.vdi"
#    Write-Host "VDI-bestand overgekopieerd" -ForegroundColor Green
#    
#    vboxmanage createvm --name="$($VM.VMName)" --ostype="Ubuntu_64" --register
#    vboxmanage modifyvm "$($VM.VMName)" --memory 1024 --vram 128 
#    VBoxManage modifyvm "$($VM.VMName)" --natpf1 "SSH,tcp,,$($VM.portforwarding.hostport),,$($VM.portforwarding.vmport)"
#    VBoxManage modifyvm "$($VM.VMName)" --natpf1 "NGINX,tcp,,8080,,80"
#    vboxmanage storagectl "$($VM.VMName)" --name "SATA Controller" --add sata --controller IntelAhci
#    vboxmanage storageattach "$($VM.VMName)" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "C:\Users\vlind\VirtualBox VMs\$($VM.VMname)\UbuntuSV24_04.vdi"
#    VBoxManage storageattach "$($VM.VMName)" --storagectl "SATA Controller" --port 1 --device 0 --type dvddrive --medium "C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso"
#    
#    #VM STARTEN
#    Write-Host "INSTALLATIE SUCCESVOL NU VM STARTEN" -ForegroundColor Yellow 
#
#    write-host "$($VM.VMName) krijgt nu guestadditions en applicaties."
#    #$vmApplicationsArray = @($VM.VMApplications)
#    & ".\installApplications1.3.ps1" -username $username -password $password -hostname $hostname -vmname $($VM.VMName) -vmapplications $($VM.VMApplications)
#
#    #NETPLAN APPLY SCRIPT AANROEPEN
#    write-host "$($VM.VMName) netwerk." -ForegroundColor Yellow
#    & ".\netplanApply.ps1" -username $username -password $password -hostname $hostname -vmname $($VM.VMName) 
#}

foreach ($VM in $jsoncontent.VMs)
{
    INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$($VM.VMName) krijgt nu guestadditions en applicaties."
    $vmApplicationsArray = @($VM.VMApplications)
    & ".\installApplications1.3.ps1" -username $username -password $password -hostname $hostname -vmname $($VM.VMName) -vmapplications $($VM.VMApplications)

    NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$($VM.VMName) netwerk." -ForegroundColor Yellow
    & ".\netplanApply.ps1" -username $username -password $password -hostname $hostname -vmname $($VM.VMName) 
}

