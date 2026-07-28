Add-VpnConnection -Name "Hope Christian College" -ServerAddress "hopecc.chsecure.zone" -RememberCredential -AllUserConnection
Add-VpnConnectionRoute -ConnectionName "Hope Christian College" -DestinationPrefix 192.168.0.0/22 -AllUserConnection
