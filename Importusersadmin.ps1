If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-noProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}
cd C:\Engineer\ImportUser\
Import-Csv .\HCCImportStudent.csv | foreach-object {
New-ADUser -Name $_.DisplayName -UserPrincipalName $_.UserPrincipalName -SamAccountName $_.SamAccountName -GivenName $_.GivenName -DisplayName $_.DisplayName -SurName $_.Surname -Description $_.Description -EmailAddress $_.EmailAddress -Department $_.Department -HomeDrive $_.HomeDrive -HomeDirectory $_.HomeDirectory -Office $_.Office -ProfilePath $_.ProfilePath -Path $_.Path -AccountPassword (ConvertTo-SecureString $_.Password -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru 
Add-ADGroupMember -Identity $_.Group -Members $_.SamAccountName -PassThru }
pause