If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-noProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

Add-VpnConnection -Name "Hope Christian College" -ServerAddress "hopecc.chsecure.zone" -RememberCredential -AllUserConnection


Add-VpnConnectionRoute -ConnectionName "Hope Christian College" -DestinationPrefix 192.168.0.0/22 -AllUserConnection

# Add Certificate

$file = ".\cacert.cer"

$file | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root

#Add user to VPN group

$Staffname = Read-Host

Add-ADGroupMember -Identity "VPN Access" -Members "$Staffname" -PassThru

