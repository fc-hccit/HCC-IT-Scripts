Function Reset {
    $simplepass = Invoke-RestMethod -Uri https://www.dinopass.com/password/simple
    $User = $ComboBox3.SelectedItem

    Set-ADAccountPassword -Identity $User -NewPassword (ConvertTo-SecureString -AsPlainText $simplepass -Force)
       
    gam update user "$User.student@hopecc.sa.edu.au" password $simplepass

    # Write username and password to text file
    "$User - $simplepass" | Out-File -FilePath "student_dinopass.txt" -Append

    $notification.ShowBalloonTip(5000, "Success", "Password has been changed successfully!", [System.Windows.Forms.ToolTipIcon]::Info)
}

# Get Users
$PrimarySchoolOU = "OU=Primary School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
$JuniorschoolOU = "OU=Junior School,OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au"
$users = Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase $PrimarySchoolOU | Select-Object -ExpandProperty SamAccountName
$users += Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase $JuniorSchoolOU | Select-Object -ExpandProperty SamAccountName

# Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form = New-Object System.Windows.Forms.Form
$Form.ClientSize = '350,130'
$Form.text = "Reset student computer and email password"
$Form.TopMost = $true
$Form.StartPosition = "CenterScreen"
$Form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$PSScriptRoot\Reset student computer and email password.exe")

$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.Visible = $true

$Button4 = New-Object System.Windows.Forms.Button
$Button4.text = "Reset Password"
$Button4.width = 120
$Button4.height = 30
$Button4.location = New-Object System.Drawing.Point(210,40)
$Button4.Font = 'Microsoft Sans Serif,10'
$Button4.Add_Click({Reset})

$ComboBox3 = New-Object System.Windows.Forms.ComboBox
$ComboBox3.text = "Student Name"
$ComboBox3.width = 130
$ComboBox3.height = 30
foreach ($user in $users) {
    $ComboBox3.Items.Add($user)
}
$ComboBox3.sorted = $true
$ComboBox3.AutoCompleteMode = 'Suggest'
$ComboBox3.AutoCompleteSource = 'ListItems'
$ComboBox3.location = New-Object System.Drawing.Point(30,40)
$ComboBox3.Font = 'Microsoft Sans Serif,10'

$ComboBox3.add_SelectedIndexChanged({
    if ($ComboBox3.SelectedIndex -ne -1) {
        $Button4.Enabled = $true
    }
})

$Form.controls.AddRange(@($Button4,$ComboBox3))

[void]$Form.ShowDialog()
