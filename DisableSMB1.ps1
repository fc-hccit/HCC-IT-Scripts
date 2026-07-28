Set-SmbServerConfiguration -EnableSMB1Protocol $false -force
Disable-WindowsOptionalFeature -Online -FeatureName smb1protocol -NoRestart