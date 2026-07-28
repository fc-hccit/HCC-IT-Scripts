# vpn_setup.ps1

# Add VPN Connection
Add-VpnConnection -Name "Hope Christian College" -ServerAddress "hopecc.chsecure.zone" -RememberCredential -AllUserConnection

# Add VPN Connection Route
Add-VpnConnectionRoute -ConnectionName "Hope Christian College" -DestinationPrefix 192.168.0.0/22 -AllUserConnection
