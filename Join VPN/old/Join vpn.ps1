Add-VpnConnection -Name "Hope Christian College" -ServerAddress "hopecc.chsecure.zone" -RememberCredential -AllUserConnection


Add-VpnConnectionRoute -ConnectionName "Hope Christian College" -DestinationPrefix 192.168.0.0/22 -AllUserConnection

# Add Certificate

$file = Get-Item "G:\Shared drives\ICT\ICT Scripts\Join VPN\cacert.cer"

$file | Import-Certificate -CertStoreLocation cert:\LocalMachine\Root

#Add user to VPN group

$Staffname = Read-Host -prompt "Please enter Staff name"

Add-ADGroupMember -Identity "VPN Access" -Members "$Staffname" -PassThru

