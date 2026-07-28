Import-Certificate -FilePath "d:\cyberedge.cet" -CertStoreLocation "Cert:\LocalMachine\Root"
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\Parameters" -Name "NegotiateDH2048_AES256" -Value 2 -Type DWord
Add-VpnConnection -Name "Hope Christian College" -ServerAddress "479193.slsecure.zone" -AllUserConnection
Set-VpnConnectionIPsecConfiguration -ConnectionName "Hope Christian College" -IntegrityCheckMethod SHA256 -AuthenticationTransformConstants GCMAES256 -CipherTransformConstants GCMAES256 -DHGroup ECP384 -EncryptionMethod GCMAES256 -PfsGroup ECP384