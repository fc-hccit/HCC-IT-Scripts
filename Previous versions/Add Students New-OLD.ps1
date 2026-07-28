<# This form was created using POSHGUI.com a free online gui designer for PowerShell
.NAME
    Untitled
#>
Function Get-FileName($initialDirectory)
{  
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) |
 Out-Null

 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = “All files (*.*)| *.*”
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
 $csvfile = $OpenFileDialog.filename
 AddStudentsCSV
 }

#Add Students via CSV

function AddStudentsCSV {

# Domain
$Domain = "hopecc.sa.edu.au"
$0to5pwd = "hcc123"
$6to12pwd = "hope1234"
$Emailsender = "alerts"
$Emailsendername = "New Student"
$Emailrecipient = "itsupport"
$Emailrecipientname = "IT Support"
$logpath = "$env:HOMEPATH\Desktop\adduser.log"

Start-Transcript -path $logpath -append

$Status.text = "Checking Name Length.."

Import-Csv "$csvfile" | ForEach-Object {


# CSV Students
$SY = $_.Year.Trim()
$SF = $_.Firstname.Trim()
$SL = $_.Lastname.Trim()
$SN = $SF + "." + $SL
$SYStudents = $SY+"Students"


if ($SN.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$SN contains more than 20 Characters", 'Error', 'OK', 'Error')}
}

# Display Confirmation

$Status.text = "Please Confirm.."


$confirm = [System.Windows.Forms.MessageBox]::Show("You are about to add students from the following CSV!`n $csvfile`n", 'Please Confirm', 'YesNo', 'Warning')

if ($confirm -eq 'Yes') {

Write-Host "working"

#begin

Import-Csv "$csvfile" | ForEach-Object {

# CSV Students
$SY = $_.Year.Trim()
$SF = $_.Firstname.Trim()
$SL = $_.Lastname.Trim()
$SN = $SF + "." + $SL
$SYStudents = $SY+"Students"

if ($SY -eq "") {$Status.text = "First Student Not Present.."
$Wait}

elseif ($SY -In 0..2) { 
$Status.text = "Creating AD Account for $SF $SL.."
$Wait
New-ADUser -Name "$SF $SL"  -UserPrincipalName "$SF.$SL@$Domain" -SamAccountName "$SF.$SL" -GivenName $SF -DisplayName "$SF $SL" -SurName "$SL" -Description "Junior School" -EmailAddress "$SF.$SL.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$SF.$SL" -Office "$SY" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $SY,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $SF $SL to Year $SY Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $SY Students" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsYr$SY Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$SY" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$SF.$SL" -PassThru 
}

elseif ($SY -In 3..5) { 
$Status.text = "Creating AD Account for $SF $SL.."
$Wait
New-ADUser -Name "$SF $SL"  -UserPrincipalName "$SF.$SL@$Domain" -SamAccountName "$SF.$SL" -GivenName $SF -DisplayName "$SF $SL" -SurName "$SL" -Description "Primary School" -EmailAddress "$SF.$SL.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$SF.$SL" -Office "$SY" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $SY,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $SF $SL to Year $SY Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $SY Students" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsYr$SY Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$SY" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$SF.$SL" -PassThru 
}

elseif ($SY -In 6..9) { 
$Status.text = "Creating AD Account for $SF $SL.."
$Wait
New-ADUser -Name "$SF $SL"  -UserPrincipalName "$SF.$SL@$Domain" -SamAccountName "$SF.$SL" -GivenName $SF -DisplayName "$SF $SL" -SurName "$SL" -Description "Middle School" -EmailAddress "$SF.$SL.student@$Domain" -Department "Students" -Office "$SY" -Path "OU=Year $SY,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $SF $SL to Year $SY Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $SY Students" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsYr$SY Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$SY" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$SF.$SL" -PassThru
$Status.text = "Creating Email Account $SF.$SL.student@$Domain"
$Wait
gam create user "$SF.$SL.student@$Domain" firstname "$SF" lastname "$SL" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $SY Students"
$Status.text = "Adding User $SF $SL to Year$SYStudents Email Group.."
$Wait
gam update group "Year$SYStudents" add "member" user "$SF.$SL.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $SF $SL" -Body "Hi Dan, `n`nI've just created a computer and email account for $SF $SL who will be in year $SY.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($SY -In 10..12) { 
$Status.text = "Creating AD Account for $SF $SL.."
$Wait
New-ADUser -Name "$SF $SL"  -UserPrincipalName "$SF.$SL@$Domain" -SamAccountName "$SF.$SL" -GivenName $SF -DisplayName "$SF $SL" -SurName "$SL" -Description "Senior School" -EmailAddress "$SF.$SL.student@$Domain" -Department "Students" -Office "$SY" -Path "OU=Year $SY,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $SF $SL to Year $SY Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $SY Students" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsYr$SY Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$SY" -Members "$SF.$SL" -PassThru
$Status.text = "Adding User $SF $SL to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$SF.$SL" -PassThru
$Status.text = "Creating Email Account $SF.$SL.student@$Domain"
$Wait
gam create user "$SF.$SL.student@$Domain" firstname "$SF" lastname "$SL" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $SY Students"
$Status.text = "Adding User $SF $SL to Year$SYStudents Email Group.."
$Wait
gam update group "Year$SYStudents" add "member" user "$SF.$SL.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $SF $SL" -Body "Hi Dan, `n`nI've just created a computer and email account for $SF $SL who will be in year $SY.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}


else {$Status.text = "No Students Added"}
}
$Status.text = "Finished"
$Add.text = "Done"}}

# Add Students Manually

function AddStudentsManually {

# Student 1
$S1Y = $S1YR.Text.Trim()
$S1N = $S1.Text.Trim()
$S1F,$S1L = $S1N.split()
$S1YStudents = $S1Y+"Students"
# Student 2
$S2Y = $S2YR.Text.Trim()
$S2N = $S2.Text.Trim()
$S2F,$S2L = $S2N.split()
$S2YStudents = $S2Y+"Students"
# Student 3
$S3Y = $S3YR.Text.Trim()
$S3N = $S3.Text.Trim()
$S3F,$S3L = $S3N.split()
$S3YStudents = $S3Y+"Students"
# Student 4
$S4Y = $S4YR.Text.Trim()
$S4N = $S4.Text.Trim()
$S4F,$S4L = $S4N.split()
$S4YStudents = $S4Y+"Students"
# Student 5
$S5Y = $S5YR.Text.Trim()
$S5N = $S5.Text.Trim()
$S5F,$S5L = $S5N.split()
$S5YStudents = $S5Y+"Students"
# Domain
$Domain = "hopecc.sa.edu.au"
$0to5pwd = "hcc123"
$6to12pwd = "hope1234"
$Emailsender = "alerts"
$Emailsendername = "New Student"
$Emailrecipient = "itsupport"
$Emailrecipientname = "IT Support"
$Wait = Start-Sleep 2
$logpath = "$env:HOMEPATH\Desktop\adduser.log"

#Start Transcript

Start-Transcript -path $logpath -append

$Status.text = "Starting Transcript.."
$Wait

# Check Username Length

if ($S1N.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$S1N contains more than 20 Characters", 'Error', 'OK', 'Error')}
if ($S2N.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$S2N contains more than 20 Characters", 'Error', 'OK', 'Error')}
if ($S3N.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$S3N contains more than 20 Characters", 'Error', 'OK', 'Error')}
if ($S4N.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$S4N contains more than 20 Characters", 'Error', 'OK', 'Error')}
if ($S5N.length -gt 20) {[System.Windows.Forms.MessageBox]::Show("$S5N contains more than 20 Characters", 'Error', 'OK', 'Error')}

# Display Confirmation

$Status.text = "Please Confirm.."
$wait

$confirm = [System.Windows.Forms.MessageBox]::Show("You are about to add the following students!`n1: Year $s1y  -  $s1f.$s1l`n2: Year $s2y  -  $s2f.$s2l`n3: Year $s3y  -  $s3f.$s3l`n4: Year $s4y  -  $s4f.$s4l`n5: Year $s5y  -  $s5f.$s5l`n", 'Please Confirm', 'YesNo', 'Warning')

if ($confirm -eq 'Yes') {

# Process first line

$Status.text = "Checking First Student.."
$Wait

if ($S1Y -eq "") {$Status.text = "First Student Not Present.."
$Wait}

elseif ($S1Y -In 0..2) { 
$Status.text = "Creating AD Account for $S1F $S1L.."
$Wait
New-ADUser -Name "$S1F $S1L"  -UserPrincipalName "$S1F.$S1L@$Domain" -SamAccountName "$S1F.$S1L" -GivenName $S1F -DisplayName "$S1F $S1L" -SurName "$S1L" -Description "Junior School" -EmailAddress "$S1F.$S1L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S1F.$S1L" -Office "$S1Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S1Y,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S1F $S1L to Year $S1Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S1Y Students" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsYr$S1Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S1Y" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$S1F.$S1L" -PassThru 
}

elseif ($S1Y -In 3..5) { 
$Status.text = "Creating AD Account for $S1F $S1L.."
$Wait
New-ADUser -Name "$S1F $S1L"  -UserPrincipalName "$S1F.$S1L@$Domain" -SamAccountName "$S1F.$S1L" -GivenName $S1F -DisplayName "$S1F $S1L" -SurName "$S1L" -Description "Primary School" -EmailAddress "$S1F.$S1L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S1F.$S1L" -Office "$S1Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S1Y,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S1F $S1L to Year $S1Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S1Y Students" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsYr$S1Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S1Y" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$S1F.$S1L" -PassThru 
}

elseif ($S1Y -In 6..9) { 
$Status.text = "Creating AD Account for $S1F $S1L.."
$Wait
New-ADUser -Name "$S1F $S1L"  -UserPrincipalName "$S1F.$S1L@$Domain" -SamAccountName "$S1F.$S1L" -GivenName $S1F -DisplayName "$S1F $S1L" -SurName "$S1L" -Description "Middle School" -EmailAddress "$S1F.$S1L.student@$Domain" -Department "Students" -Office "$S1Y" -Path "OU=Year $S1Y,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S1F $S1L to Year $S1Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S1Y Students" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsYr$S1Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S1Y" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$S1F.$S1L" -PassThru
$Status.text = "Creating Email Account $S1F.$S1L.student@$Domain"
$Wait
gam create user "$S1F.$S1L.student@$Domain" firstname "$S1F" lastname "$S1L" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $S1Y Students"
$Status.text = "Adding User $S1F $S1L to Year$S1YStudents Email Group.."
$Wait
gam update group "Year$S1YStudents" add "member" user "$S1F.$S1L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S1F $S1L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S1F $S1L who will be in year $S1Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($S1Y -In 10..12) { 
$Status.text = "Creating AD Account for $S1F $S1L.."
$Wait
New-ADUser -Name "$S1F $S1L"  -UserPrincipalName "$S1F.$S1L@$Domain" -SamAccountName "$S1F.$S1L" -GivenName $S1F -DisplayName "$S1F $S1L" -SurName "$S1L" -Description "Senior School" -EmailAddress "$S1F.$S1L.student@$Domain" -Department "Students" -Office "$S1Y" -Path "OU=Year $S1Y,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S1F $S1L to Year $S1Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S1Y Students" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsYr$S1Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S1Y" -Members "$S1F.$S1L" -PassThru
$Status.text = "Adding User $S1F $S1L to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$S1F.$S1L" -PassThru
$Status.text = "Creating Email Account $S1F.$S1L.student@$Domain"
$Wait
gam create user "$S1F.$S1L.student@$Domain" firstname "$S1F" lastname "$S1L" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $S1Y Students"
$Status.text = "Adding User $S1F $S1L to Year$S1YStudents Email Group.."
$Wait
gam update group "Year$S1YStudents" add "member" user "$S1F.$S1L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S1F $S1L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S1F $S1L who will be in year $S1Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

else {$Status.text = "First Student Not Present.."
$Wait}

# Process second line

$Wait

if ($S2Y -eq "") {$Status.text = "Second Student Not Present.."
$Wait}

elseif ($S2Y -In 0..2) { 
$Status.text = "Creating AD Account for $S2F $S2L.."
$Wait
New-ADUser -Name "$S2F $S2L"  -UserPrincipalName "$S2F.$S2L@$Domain" -SamAccountName "$S2F.$S2L" -GivenName $S2F -DisplayName "$S2F $S2L" -SurName "$S2L" -Description "Junior School" -EmailAddress "$S2F.$S2L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S2F.$S2L" -Office "$S2Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S2Y,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S2F $S2L to Year $S2Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S2Y Students" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsYr$S2Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S2Y" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$S2F.$S2L" -PassThru 
}

elseif ($S2Y -In 3..5) {
$Status.text = "Creating AD Account for $S2F $S2L.."
$Wait
New-ADUser -Name "$S2F $S2L"  -UserPrincipalName "$S2F.$S2L@$Domain" -SamAccountName "$S2F.$S2L" -GivenName $S2F -DisplayName "$S2F $S2L" -SurName "$S2L" -Description "Primary School" -EmailAddress "$S2F.$S2L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S2F.$S2L" -Office "$S2Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S2Y,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S2F $S2L to Year $S2Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S2Y Students" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsYr$S2Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S2Y" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$S2F.$S2L" -PassThru  
}

elseif ($S2Y -In 6..9) {
$Status.text = "Creating AD Account for $S2F $S2L.."
$Wait
New-ADUser -Name "$S2F $S2L"  -UserPrincipalName "$S2F.$S2L@$Domain" -SamAccountName "$S2F.$S2L" -GivenName $S2F -DisplayName "$S2F $S2L" -SurName "$S2L" -Description "Middle School" -EmailAddress "$S2F.$S2L.student@$Domain" -Department "Students" -Office "$S2Y" -Path "OU=Year $S2Y,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S2F $S2L to Year $S2Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S2Y Students" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsYr$S2Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S2Y" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$S2F.$S2L" -PassThru
$Status.text = "Creating Email Account $S2F.$S2L.student@$Domain"
$Wait
gam create user "$S2F.$S2L.student@$Domain" firstname "$S2F" lastname "$S2L" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $S2Y Students"
$Status.text = "Adding User $S2F $S2L to Year$S2YStudents Email Group.."
$Wait
gam update group "Year$S2YStudents" add "member" user "$S2F.$S2L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S2F $S2L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S2F $S2L who will be in year $S2Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($S2Y -In 10..12) {
$Status.text = "Creating AD Account for $S2F $S2L.."
$Wait
New-ADUser -Name "$S2F $S2L"  -UserPrincipalName "$S2F.$S2L@$Domain" -SamAccountName "$S2F.$S2L" -GivenName $S2F -DisplayName "$S2F $S2L" -SurName "$S2L" -Description "Senior School" -EmailAddress "$S2F.$S2L.student@$Domain" -Department "Students" -Office "$S2Y" -Path "OU=Year $S2Y,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S2F $S2L to Year $S2Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S2Y Students" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsYr$S2Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S2Y" -Members "$S2F.$S2L" -PassThru
$Status.text = "Adding User $S2F $S2L to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$S2F.$S2L" -PassThru
$Status.text = "Creating Email Account $S2F.$S2L.student@$Domain"
$Wait
gam create user "$S2F.$S2L.student@$Domain" firstname "$S2F" lastname "$S2L" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $S2Y Students"
$Status.text = "Adding User $S2F $S2L to Year$S2YStudents Email Group.."
$Wait
gam update group "Year$S2YStudents" add "member" user "$S2F.$S2L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S2F $S2L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S2F $S2L who will be in year $S2Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

else {$Status.text = "Second Student Not Present.."
$Wait}

# Process third line

$Wait

if ($S3Y -eq "") {$Status.text = "Third Student Not Present.."
$Wait}

elseif ($S3Y -In 0..2) { 
$Status.text = "Creating AD Account for $S3F $S3L.."
$Wait
New-ADUser -Name "$S3F $S3L"  -UserPrincipalName "$S3F.$S3L@$Domain" -SamAccountName "$S3F.$S3L" -GivenName $S3F -DisplayName "$S3F $S3L" -SurName "$S3L" -Description "Junior School" -EmailAddress "$S3F.$S3L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S3F.$S3L" -Office "$S3Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S3Y,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S3F $S3L to Year $S3Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S3Y Students" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsYr$S3Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S3Y" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$S3F.$S3L" -PassThru
}

elseif ($S3Y -In 3..5) {
$Status.text = "Creating AD Account for $S3F $S3L.."
$Wait
New-ADUser -Name "$S3F $S3L"  -UserPrincipalName "$S3F.$S3L@$Domain" -SamAccountName "$S3F.$S3L" -GivenName $S3F -DisplayName "$S3F $S3L" -SurName "$S3L" -Description "Primary School" -EmailAddress "$S3F.$S3L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S3F.$S3L" -Office "$S3Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S3Y,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S3F $S3L to Year $S3Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S3Y Students" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsYr$S3Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S3Y" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$S3F.$S3L" -PassThru  
}

elseif ($S3Y -In 6..9) {
$Status.text = "Creating AD Account for $S3F $S3L.."
$Wait
New-ADUser -Name "$S3F $S3L"  -UserPrincipalName "$S3F.$S3L@$Domain" -SamAccountName "$S3F.$S3L" -GivenName $S3F -DisplayName "$S3F $S3L" -SurName "$S3L" -Description "Middle School" -EmailAddress "$S3F.$S3L.student@$Domain" -Department "Students" -Office "$S3Y" -Path "OU=Year $S3Y,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S3F $S3L to Year $S3Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S3Y Students" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsYr$S3Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S3Y" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$S3F.$S3L" -PassThru
$Status.text = "Creating Email Account $S3F.$S3L.student@$Domain"
$Wait
gam create user "$S3F.$S3L.student@$Domain" firstname "$S3F" lastname "$S3L" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $S3Y Students"
$Status.text = "Adding User $S3F $S3L to Year$S3YStudents Email Group.."
$Wait
gam update group "Year$S3YStudents" add "member" user "$S3F.$S3L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S3F $S3L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S3F $S3L who will be in year $S3Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($S3Y -In 10..12) {
$Status.text = "Creating AD Account for $S3F $S3L.."
$Wait
New-ADUser -Name "$S3F $S3L"  -UserPrincipalName "$S3F.$S3L@$Domain" -SamAccountName "$S3F.$S3L" -GivenName $S3F -DisplayName "$S3F $S3L" -SurName "$S3L" -Description "Senior School" -EmailAddress "$S3F.$S3L.student@$Domain" -Department "Students" -Office "$S3Y" -Path "OU=Year $S3Y,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S3F $S3L to Year $S3Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S3Y Students" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsYr$S3Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S3Y" -Members "$S3F.$S3L" -PassThru
$Status.text = "Adding User $S3F $S3L to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$S3F.$S3L" -PassThru
$Status.text = "Creating Email Account $S3F.$S3L.student@$Domain"
$Wait
gam create user "$S3F.$S3L.student@$Domain" firstname "$S3F" lastname "$S3L" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $S3Y Students"
$Status.text = "Adding User $S3F $S3L to Year$S3YStudents Email Group.."
$Wait
gam update group "Year$S3YStudents" add "member" user "$S3F.$S3L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S3F $S3L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S3F $S3L who will be in year $S3Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

else {$Status.text = "Third Student Not Present.."
$Wait}

# Process fourth line

$Wait

if ($S4Y -eq "") {$Status.text = "Fourth Student Not Present.."
$Wait}

elseif ($S4Y -In 0..2) { 
$Status.text = "Creating AD Account for $S4F $S4L.."
$Wait
New-ADUser -Name "$S4F $S4L"  -UserPrincipalName "$S4F.$S4L@$Domain" -SamAccountName "$S4F.$S4L" -GivenName $S4F -DisplayName "$S4F $S4L" -SurName "$S4L" -Description "Junior School" -EmailAddress "$S4F.$S4L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S4F.$S4L" -Office "$S4Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S4Y,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S4F $S4L to Year $S4Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S4Y Students" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsYr$S4Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S4Y" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$S4F.$S4L" -PassThru
}

elseif ($S4Y -In 3..5) {
$Status.text = "Creating AD Account for $S4F $S4L.."
$Wait
New-ADUser -Name "$S4F $S4L"  -UserPrincipalName "$S4F.$S4L@$Domain" -SamAccountName "$S4F.$S4L" -GivenName $S4F -DisplayName "$S4F $S4L" -SurName "$S4L" -Description "Primary School" -EmailAddress "$S4F.$S4L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S4F.$S4L" -Office "$S4Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S4Y,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S4F $S4L to Year $S4Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S4Y Students" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsYr$S4Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S4Y" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$S4F.$S4L" -PassThru  
}

elseif ($S4Y -In 6..9) {
$Status.text = "Creating AD Account for $S4F $S4L.."
$Wait
New-ADUser -Name "$S4F $S4L"  -UserPrincipalName "$S4F.$S4L@$Domain" -SamAccountName "$S4F.$S4L" -GivenName $S4F -DisplayName "$S4F $S4L" -SurName "$S4L" -Description "Middle School" -EmailAddress "$S4F.$S4L.student@$Domain" -Department "Students" -Office "$S4Y" -Path "OU=Year $S4Y,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S4F $S4L to Year $S4Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S4Y Students" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsYr$S4Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S4Y" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$S4F.$S4L" -PassThru
$Status.text = "Creating Email Account $S4F.$S4L.student@$Domain"
$Wait
gam create user "$S4F.$S4L.student@$Domain" firstname "$S4F" lastname "$S4L" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $S4Y Students"
$Status.text = "Adding User $S4F $S4L to Year$S4YStudents Email Group.."
$Wait
gam update group "Year$S4YStudents" add "member" user "$S4F.$S4L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S4F $S4L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S4F $S4L who will be in year $S4Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($S4Y -In 10..12) {
$Status.text = "Creating AD Account for $S4F $S4L.."
$Wait
New-ADUser -Name "$S4F $S4L"  -UserPrincipalName "$S4F.$S4L@$Domain" -SamAccountName "$S4F.$S4L" -GivenName $S4F -DisplayName "$S4F $S4L" -SurName "$S4L" -Description "Senior School" -EmailAddress "$S4F.$S4L.student@$Domain" -Department "Students" -Office "$S4Y" -Path "OU=Year $S4Y,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S4F $S4L to Year $S4Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S4Y Students" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsYr$S4Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S4Y" -Members "$S4F.$S4L" -PassThru
$Status.text = "Adding User $S4F $S4L to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$S4F.$S4L" -PassThru
$Status.text = "Creating Email Account $S4F.$S4L.student@$Domain"
$Wait
gam create user "$S4F.$S4L.student@$Domain" firstname "$S4F" lastname "$S4L" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $S4Y Students"
$Status.text = "Adding User $S4F $S4L to Year$S4YStudents Email Group.."
$Wait
gam update group "Year$S4YStudents" add "member" user "$S4F.$S4L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S4F $S4L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S4F $S4L who will be in year $S4Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

else {$Status.text = "Fourth Student Not Present.."
$Wait}

# Process fith line

$Wait

if ($S5Y -eq "") {$Status.text = "Fifth Student Not Present.."
$Wait}

elseif ($S5Y -In 0..2) { 
$Status.text = "Creating AD Account for $S5F $S5L.."
$Wait
New-ADUser -Name "$S5F $S5L"  -UserPrincipalName "$S5F.$S5L@$Domain" -SamAccountName "$S5F.$S5L" -GivenName $S5F -DisplayName "$S5F $S5L" -SurName "$S5L" -Description "Junior School" -EmailAddress "$S5F.$S5L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S5F.$S5L" -Office "$S5Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S5Y,OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S5F $S5L to Year $S5Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S5Y Students" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsYr$S5Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S5Y" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsJrPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsJrPrimary" -Members "$S5F.$S5L" -PassThru
}

elseif ($S5Y -In 3..5) {
$Status.text = "Creating AD Account for $S5F $S5L.."
$Wait
New-ADUser -Name "$S5F $S5L"  -UserPrincipalName "$S5F.$S5L@$Domain" -SamAccountName "$S5F.$S5L" -GivenName $S5F -DisplayName "$S5F $S5L" -SurName "$S5L" -Description "Primary School" -EmailAddress "$S5F.$S5L.student@$Domain" -Department "Students" -HomeDrive H: -HomeDirectory "\\$Domain\Student\StudentHome\$S5F.$S5L" -Office "$S5Y" -ProfilePath "\\$Domain\Student\StudentProfiles\Mandatory" -Path "OU=Year $S5Y,OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$0to5pwd" -AsPlainText -force) -Enabled $True -CannotChangePassword $True -PasswordNeverExpires $True -PassThru
$Status.text = "Adding User $S5F $S5L to Year $S5Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S5Y Students" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsYr$S5Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S5Y" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsPrimary Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsPrimary" -Members "$S5F.$S5L" -PassThru  
}

elseif ($S5Y -In 6..9) {
$Status.text = "Creating AD Account for $S5F $S5L.."
$Wait
New-ADUser -Name "$S5F $S5L"  -UserPrincipalName "$S5F.$S5L@$Domain" -SamAccountName "$S5F.$S5L" -GivenName $S5F -DisplayName "$S5F $S5L" -SurName "$S5L" -Description "Middle School" -EmailAddress "$S5F.$S5L.student@$Domain" -Department "Students" -Office "$S5Y" -Path "OU=Year $S5Y,OU=Middle School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S5F $S5L to Year $S5Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S5Y Students" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsYr$S5Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S5Y" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsMiddle Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsMiddle" -Members "$S5F.$S5L" -PassThru
$Status.text = "Creating Email Account $S5F.$S5L.student@$Domain"
$Wait
gam create user "$S5F.$S5L.student@$Domain" firstname "$S5F" lastname "$S5L" password "$6to12pwd" changepassword "on" org "Middle School Students (Restricted)/Year $S5Y Students"
$Status.text = "Adding User $S5F $S5L to Year$S5YStudents Email Group.."
$Wait
gam update group "Year$S5YStudents" add "member" user "$S5F.$S5L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S5F $S5L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S5F $S5L who will be in year $S5Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

elseif ($S5Y -In 10..12) {
$Status.text = "Creating AD Account for $S5F $S5L.."
$Wait
New-ADUser -Name "$S5F $S5L"  -UserPrincipalName "$S5F.$S5L@$Domain" -SamAccountName "$S5F.$S5L" -GivenName $S5F -DisplayName "$S5F $S5L" -SurName "$S5L" -Description "Senior School" -EmailAddress "$S5F.$S5L.student@$Domain" -Department "Students" -Office "$S5Y" -Path "OU=Year $S5Y,OU=Senior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au" -AccountPassword (ConvertTo-SecureString "$6to12pwd" -AsPlainText -force) -Enabled $True -ChangePasswordAtLogon $True -PassThru
$Status.text = "Adding User $S5F $S5L to Year $S5Y Students Group.."
$Wait
Add-ADGroupMember -Identity "Year $S5Y Students" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsYr$S5Y Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsYr$S5Y" -Members "$S5F.$S5L" -PassThru
$Status.text = "Adding User $S5F $S5L to gpOUStudentsSenior Group.."
$Wait
Add-ADGroupMember -Identity "gpOUStudentsSenior" -Members "$S5F.$S5L" -PassThru
$Status.text = "Creating Email Account $S5F.$S5L.student@$Domain"
$Wait
gam create user "$S5F.$S5L.student@$Domain" firstname "$S5F" lastname "$S5L" password "$6to12pwd" changepassword "on" org "Senior School Students/Year $S5Y Students"
$Status.text = "Adding User $S5F $S5L to Year$S5YStudents Email Group.."
$Wait
gam update group "Year$S5YStudents" add "member" user "$S5F.$S5L.student@$Domain"
$Status.text = "Sending Email.."
$Wait
Send-MailMessage -From "$emailsendername <$emailsender@$Domain>" -To "$emailrecipientname <$emailrecipient@$Domain>" -Subject "Please prepare a laptop for $S5F $S5L" -Body "Hi Dan, `n`nI've just created a computer and email account for $S5F $S5L who will be in year $S5Y.`n`nPlease prepare a laptop for them to use." -SmtpServer "aspmx.l.google.com"
}

else {$Status.text = "Fifth Student Not Present.."
$Wait}


}

else {$Status.text = "You Cancelled at Confirmation"
$Wait}

$Status.text = "Stopping Transcript"
$Wait

Stop-Transcript

$Status.text = "Finished"
$Wait

$Add.text = "Done"

}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '430,210'
$Form.text                       = "Add Students to Active Directory & G-Suite"
$form.StartPosition              = 'CenterScreen'
$Form.TopMost                    = $false
$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon                       = $Icon
#Student 1
$S1YR                            = New-Object system.Windows.Forms.ComboBox
$S1YR.width                      = 100
$S1YR.height                     = 20
$S1YR.DropDownStyle              = 'DropDownList'
@('0','1','2','3','4','5','6','7','8','9','10','11','12') | ForEach-Object {[void] $S1YR.Items.Add($_)}
$S1YR.location                   = New-Object System.Drawing.Point(10,30)
$S1YR.Font                       = 'Microsoft Sans Serif,10'
$S1YR.add_SelectedIndexChanged({ if($S1YR.SelectedIndex -ne "-1" -and $S1.Text) {$Add.Enabled = $true}})
#Student 2
$S2YR                            = New-Object system.Windows.Forms.ComboBox
$S2YR.width                      = 100
$S2YR.height                     = 20
$S2YR.DropDownStyle              = 'DropDownList'
@('0','1','2','3','4','5','6','7','8','9','10','11','12') | ForEach-Object {[void] $S2YR.Items.Add($_)}
$S2YR.location                   = New-Object System.Drawing.Point(10,60)
$S2YR.Font                       = 'Microsoft Sans Serif,10'
#Student 3
$S3YR                            = New-Object system.Windows.Forms.ComboBox
$S3YR.width                      = 100
$S3YR.height                     = 20
$S3YR.DropDownStyle              = 'DropDownList'
@('0','1','2','3','4','5','6','7','8','9','10','11','12') | ForEach-Object {[void] $S3YR.Items.Add($_)}
$S3YR.location                   = New-Object System.Drawing.Point(10,90)
$S3YR.Font                       = 'Microsoft Sans Serif,10'
#Student 4
$S4YR                            = New-Object system.Windows.Forms.ComboBox
$S4YR.width                      = 100
$S4YR.height                     = 20
$S4YR.DropDownStyle              = 'DropDownList'
@('0','1','2','3','4','5','6','7','8','9','10','11','12') | ForEach-Object {[void] $S4YR.Items.Add($_)}
$S4YR.location                   = New-Object System.Drawing.Point(10,120)
$S4YR.Font                       = 'Microsoft Sans Serif,10'
#Student 5
$S5YR                            = New-Object system.Windows.Forms.ComboBox
$S5YR.width                      = 100
$S5YR.height                     = 20
$S5YR.DropDownStyle              = 'DropDownList'
@('0','1','2','3','4','5','6','7','8','9','10','11','12') | ForEach-Object {[void] $S5YR.Items.Add($_)}
$S5YR.location                   = New-Object System.Drawing.Point(9,150)
$S5YR.Font                       = 'Microsoft Sans Serif,10'

$S1                            = New-Object system.Windows.Forms.TextBox
$S1.multiline                  = $false
$S1.width                      = 200
$S1.height                     = 20
$S1.location                   = New-Object System.Drawing.Point(130,30)
$S1.Font                       = 'Microsoft Sans Serif,10'
$S1.Add_TextChanged({ if($S1YR.SelectedIndex -ne "-1" -and $S1.Text) {$Add.Enabled = $true}})
                      

$S2                            = New-Object system.Windows.Forms.TextBox
$S2.multiline                  = $false
$S2.width                      = 200
$S2.height                     = 20
$S2.location                   = New-Object System.Drawing.Point(130,60)
$S2.Font                       = 'Microsoft Sans Serif,10'

$S3                            = New-Object system.Windows.Forms.TextBox
$S3.multiline                  = $false
$S3.width                      = 200
$S3.height                     = 20
$S3.location                   = New-Object System.Drawing.Point(130,90)
$S3.Font                       = 'Microsoft Sans Serif,10'

$S4                            = New-Object system.Windows.Forms.TextBox
$S4.multiline                  = $false
$S4.width                      = 200
$S4.height                     = 20
$S4.location                   = New-Object System.Drawing.Point(130,120)
$S4.Font                       = 'Microsoft Sans Serif,10'

$S5                            = New-Object system.Windows.Forms.TextBox
$S5.multiline                  = $false
$S5.width                      = 200
$S5.height                     = 20
$S5.location                   = New-Object System.Drawing.Point(130,150)
$S5.Font                       = 'Microsoft Sans Serif,10'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Year Level"
$Label1.AutoSize                 = $true
$Label1.width                    = 30
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(23,10)
$Label1.Font                     = 'Microsoft Sans Serif,10,style=Bold'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Firstname Lastname"
$Label2.AutoSize                 = $true
$Label2.width                    = 30
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(165,10)
$Label2.Font                     = 'Microsoft Sans Serif,10,style=Bold'

$Status                          = New-Object system.Windows.Forms.Label
$Status.text                     = "Ready..."
$Status.AutoSize                 = $true
$Status.width                    = 180
$Status.height                   = 10
$Status.location                 = New-Object System.Drawing.Point(20,185)
$Status.Font                     = 'Microsoft Sans Serif,10'

$Add                             = New-Object system.Windows.Forms.Button
$Add.text                        = "Add"
$Add.width                       = 60
$Add.height                      = 110
$Add.location                    = New-Object System.Drawing.Point(355,30)
$Add.Font                        = 'Microsoft Sans Serif,10,style=Bold'
$Add.Enabled                     = $false
$Add.Add_Click({ if ($Add.Text -eq "Add") {AddStudentsManually} Else {$Form.Close()}}) 

$Csv                             = New-Object system.Windows.Forms.Button
$Csv.text                        = "CSV"
$Csv.width                       = 60
$Csv.height                      = 30
$Csv.location                    = New-Object System.Drawing.Point(355,145)
$Csv.Font                        = 'Microsoft Sans Serif,10,style=Bold'
$Csv.Enabled                     = $true
$Csv.Add_Click({Get-FileName})



$Form.controls.AddRange(@($S1YR,$S2YR,$S3YR,$S4YR,$S5YR,$S1,$S2,$S3,$S4,$S5,$Label1,$Label2,$Status,$Add,$Csv))

#Write your logic code here

[Void]$form.ShowDialog()