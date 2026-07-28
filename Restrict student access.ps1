function Check-Status{


$username = $ComboBox1.SelectedItem
$username

$usergroups = Get-ADPrincipalGroupMembership $username | select name | Where-Object {$_.name -like '*gpRestrictedEducationalSites*' }

$Usergroupname = $usergroups.name

if($Usergroupname -like 'gpRestrictedEducationalSites') {

$Label1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#d0021b")
$Label1.text="Restricted"
}

else{
$Label1.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#7ed321")
$Label1.text = "Unrestricted"
}


}

function Change-Status{

$username = $ComboBox1.SelectedItem

$usergroups = Get-ADPrincipalGroupMembership $username | select name | Where-Object {$_.name -like '*gpRestrictedEducationalSites*' }

$Usergroupname = $usergroups.name

if($Usergroupname -like 'gpRestrictedEducationalSites') {Remove-ADGroupMember -Identity gpRestrictedEducationalSites -Members $username -Confirm:$False}

else {Add-ADGroupMember -Identity gpRestrictedEducationalSites -Members $username -Confirm:$False}

$Label1.text = "Please Wait"

Start-Sleep 2

Check-Status

}

#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(285,180)
$Form.text                       = "Student Access Status"
$Form.TopMost                    = $true
$Form.StartPosition              = 'CenterScreen'

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 180
$ComboBox1.height                = 45
ForEach($user in $users) {$combobox1.Items.Add($User)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({Check-Status; if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button1.text = "Change"}})
$ComboBox1.location              = New-Object System.Drawing.Point(46,30)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.Enabled                 = $false
$Button1.width                   = 120
$Button1.height                  = 37
$Button1.location                = New-Object System.Drawing.Point(74,120)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({Change-Status})

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Status"
$Label1.AutoSize                 = $false
$Label1.TextAlign                = 'MiddleCenter'
$Label1.Anchor                   = 'none'  
$Label1.width                    = 200
$Label1.height                   = 50
$Label1.location                 = New-Object System.Drawing.Point(35,60)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',20,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$Form.controls.AddRange(@($ComboBox1,$Button1,$Label1))




#Write your logic code here

[void]$Form.ShowDialog()