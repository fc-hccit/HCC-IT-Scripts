# Get the last logged on user from the registry
$LastLoggedOnUser = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").LastLoggedOnUser
# Remove the .\ part if it exists
$username = $LastLoggedOnUser -split '\\'
$username = $username[1]
# SiteKey
$SiteKey = "479193"
# PreSharedKey
$Presharedkey = "HCCRoamSafe!"

# Install Command

msiexec /i winAgent-1.1.0.msi USERNAME=$username SERVICE_ID=$SiteKey DEPLOYMENT_PASSWORD=$Presharedkey

