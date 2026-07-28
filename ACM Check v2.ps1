$unkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
$LastLoggedOnUser = (Get-ItemProperty -Path $unkey -Name LastLoggedOnUser).LastLoggedOnUser
$usernamesplit = $LastLoggedOnUser.split("\")

# Check if the split was successful
if ($usernamesplit.Count -gt 1) {
    $username = $usernamesplit[1]
} else {
    $username = $LastLoggedOnUser  # Use full username if split fails
}

$devicename = $env:ComputerName
$installpath = 'C:\Program Files (x86)\Acer\Acer Classroom Manager\client32.exe'

# Check if the file exists and get the version, else handle the error
if (Test-Path -Path $installpath) {
    $fileVersion = (Get-Item $installpath).VersionInfo.FileVersion
} else {
    $fileVersion = "Unknown Version"
}

# Check if ACM is installed
if (Test-Path -Path $installpath) {

    # Check if the client32 service exists
    $service = Get-Service -Name "client32" -ErrorAction SilentlyContinue

    if ($null -eq $service) {
        # If the service does not exist, but the install path exists, send an email about incorrect installation
        Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" `
                          -To "itstaff@hopecc.sa.edu.au" `
                          -Subject "ACM is installed incorrectly on $username's $devicename - Adding Service to Registry" `
                          -Body "The ACM install path exists at $installpath, but the service 'client32' is not registered. Adding Service" `
                          -SmtpServer "aspmx.l.google.com" `
                          -ErrorAction SilentlyContinue

        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "Type" /t REG_DWORD /d 0x110 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "Start" /t REG_DWORD /d 0x2 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "ErrorControl" /t REG_DWORD /d 0x1 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "ImagePath" /t REG_EXPAND_SZ /d "\"C:\\Program Files (x86)\\Acer\\Acer Classroom Manager\\client32.exe\" /* *" /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "DisplayName" /t REG_SZ /d "Client32" /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "WOW64" /t REG_DWORD /d 0x14c /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Client32" /v "ObjectName" /t REG_SZ /d "LocalSystem" /f
        shutdown -r -t 0

    } else {
        # Wait 60 Seconds
        Start-Sleep -Seconds 60

        # Check if the process is running
        if (!(Get-Process client32 -ErrorAction SilentlyContinue)) {

            # Start the client32 service if it's not running
            Start-Service -Name "client32" -ErrorAction SilentlyContinue

            # Add failure actions to the registry
            $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\client32"
            New-ItemProperty -Path $regPath -Name "FailureActions" -PropertyType Binary -Value ([byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x03,0x00,0x00,0x00,0x14,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x60,0xEA,0x00,0x00,0x01,0x00,0x00,0x00,0x60,0xEA,0x00,0x00,0x02,0x00,0x00,0x00,0x60,0xEA,0x00,0x00)) -Force

            # Send email if installed but not running
            Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" `
                              -To "itstaff@hopecc.sa.edu.au" `
                              -Subject "ACM service $fileVersion is installed but was not running on $username's $devicename - Service started and failure actions set" `
                              -SmtpServer "aspmx.l.google.com" `
                              -ErrorAction SilentlyContinue
        }
    }

} else {

    # If ACM is not installed, send an alert
    Send-MailMessage -From "ACM Alert <alerts@hopecc.sa.edu.au>" `
                      -To "itstaff@hopecc.sa.edu.au" `
                      -Subject "$username's device $devicename does not have ACM installed" `
                      -SmtpServer "aspmx.l.google.com" `
                      -ErrorAction SilentlyContinue
}
