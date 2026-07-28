Function DisableStudentCSV {

$popup = New-Object -ComObject Wscript.Shell

$CSVDetails = Get-Content $csvfile | Measure-Object -line

$LinesInFile = $CSVDetails.Lines -1
    
$confirm = [System.Windows.Forms.MessageBox]::Show("You are about to disable $LinesInFile Users!", 'Please Confirm', 'YesNo', 'Warning')

if ($confirm -eq 'Yes') {


#Count Users

$i = 1
$pct = 0

Import-Csv "$csvfile" | ForEach-Object {

$SF = $_.Firstname.Trim()
$SL = $_.Lastname.Trim()
$User = $SF + "." + $SL

$Status.text = "Disabling $user" + "`r" + "'s AD account"

# Disable AD Account

Disable-ADAccount -Identity $user
Move-ADObject -Identity $user -TargetPath "OU=Disabled User Accounts,DC=hopecc,DC=sa,DC=edu,DC=au"

$Error | Out-File ".\error.log" -Append

# Disable Email Account

$Status.text = "Disabling $user" + "`r" + "'s email account"

gam update user "$user.student@hopecc.sa.edu.au" suspended on
gam update user "$user.student@hopecc.sa.edu.au" ou "/Suspended Accounts"
 
$Error | Out-File ".\error.log" -Append

#update the progress bar

[int]$pct = ($i/$LinesInFile)*100

$progressbar.Value = ($pct)

$i++

[void] [System.Windows.Forms.Application]::DoEvents()

start-sleep 2

}

$Total = $i-1

$progressbar.Value = 100

$popup.Popup("Succesfully Disabled $Total Users",0,"Success",48+4096)

}
}

Function Get-FileName($initialDirectory){  
 [System.Reflection.Assembly]::LoadWithPartialName(“System.windows.forms”) | Out-Null
 $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
 $OpenFileDialog.initialDirectory = $initialDirectory
 $OpenFileDialog.filter = “All files (*.*)| *.*”
 $OpenFileDialog.ShowDialog() | Out-Null
 $OpenFileDialog.filename
 $csvfile = $OpenFileDialog.filename
 DisableStudentCSV
 }

Function DisableUser {

$progressbar.Value = 0

$User = $ComboBox1.SelectedItem
$Status.text = "Disabling $user" + "'s accounts"
$popup = New-Object -ComObject Wscript.Shell

    Disable-ADAccount -Identity $user
    Move-ADObject -Identity $user -TargetPath "OU=Disabled User Accounts,DC=hopecc,DC=sa,DC=edu,DC=au"
    $progressbar.Value = 50
    gam update user "$user.student@hopecc.sa.edu.au" suspended on
    gam update user "$user.student@hopecc.sa.edu.au" ou "/Suspended Accounts"

$progressbar.Value = 100
$Status.text = "$user has been successfully Disabled" 

start-sleep 2

$Button1.Text = ""
$Button1.Enabled = $false
$ComboBox1.SelectedIndex = -1
$progressbar.Value = 0
$status.Text = ""

} 

Function EnableUser { 

$progressbar.Value = 0

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem

    Enable-ADAccount -Identity $user
    $progressbar.Value = 50
    gam update user "$user.student@hopecc.sa.edu.au" suspended off

$progressbar.Value = 100
$Status.text = "$user has been successfully Enabled" 

start-sleep 2

$Button1.Text = ""
$Button1.Enabled = $false
$ComboBox1.SelectedIndex = -1
$progressbar.Value = 0
$status.Text = ""

} 


#Get Users

$users = (Get-ADUser -Filter * -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '550,100'
$Form.text                       = "Disable or Enable Users Account and Email"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("Disable Student Account and Email.exe")

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(160,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({if($Button1.Text -eq "Disable"){DisableUser} ; if($Button1.Text -eq "Enable"){EnableUser}})
$Button1.Enabled                 = $true

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.width                   = 120
$Button2.height                  = 40
$Button2.text                    = "CSV Bulk Student Disable"
$Button2.location                = New-Object System.Drawing.Point(420,4)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$Button2.Add_Click({Get-FileName})
$Button2.Enabled                 = $true

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 130
$ComboBox1.height                = 30
ForEach($user in $users) {$combobox1.Items.Add($User)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.location              = New-Object System.Drawing.Point(14,14)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {

$Button1.Enabled = $true


# Retrieve the user from Active Directory

$username = $ComboBox1.SelectedItem.ToString()

$aduser = Get-ADUser -Identity $username -Properties Enabled

# Check if the user is enabled or disabled
if ($aduser.Enabled) {
    $Button1.Text = "Disable"
} else {
    $Button1.Text = "Enable"
}
 
}})

$ProgressBar                     = New-Object system.Windows.Forms.ProgressBar
$ProgressBar.width               = 525
$ProgressBar.height              = 20
$ProgressBar.location            = New-Object System.Drawing.Point(14,50)

$Status                       = New-Object system.Windows.Forms.Label
$Status.AutoSize              = $true
$Status.width                 = 525
$Status.height                = 10
$Status.location              = New-Object System.Drawing.Point(14,75)
$Status.Font                  = 'Microsoft Sans Serif,10,style=Bold'


$Form.controls.AddRange(@($Button1,$Button2,$ComboBox1,$ProgressBar,$Status))

#Write your logic code here

[void]$Form.ShowDialog()


