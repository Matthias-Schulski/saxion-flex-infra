#### SITUATIE: VMS GEMAAKT
#### NA CONFIGURATIE MOET GEDAAN WORDEN
### PARAMETERS DIE EIGENLIJK UIT VORIGE SCRIPT MOETEN KOMEN
param (
[STRING]$VMname = "",                   #WORDT GELEVERD
[STRING]$distroname = "",               #WORDT GELEVERD
[STRING]$applications="",               #WORDT GELEVERD
[STRING]$hostport=""                    #WORDT GELEVERD
)

$username = "ubuntu" #DEFAULT USER
$password = "ubuntu" #DEFAULT WACHTWOORD
$hostname = "ubuntu" #DEFAULT DIRECTORY                 

foreach ($VM in $VMName)
{
    #INSTALLAPPLICATIONS SCRIPT AANROEPEN
    write-host "$vmname krijgt nu guestadditions en applicaties." -ForegroundColor Yellow
    & ".\installApplications1.3.ps1" -username $username -password $password -hostname $hostname -vmname $VMName -applications $applications -hostport $hostport

    #NETPLAN APPLY SCRIPT AANROEPEN
    write-host "$vmname netplan configureren." -ForegroundColor Yellow
    & ".\netplanApply.ps1" -username $username -password $password -hostname $hostname -vmname $vmname
}

