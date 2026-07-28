#Copy / Paste 

Function ExportCSV {

$firstname,$lastname = $ComboBox1.text.Split(".")

Set-Clipboard -Value "$firstname $lastname"

$details = @{            
                Date             = get-date              
                DamageType       = $ComboBox2.SelectedItem                 
                StudentName      = "$firstname $lastname"
        }                           
        $results += New-Object PSObject -Property $details  

$results | export-csv -Path "G:\Shared drives\ICT\ICT Share\Logs\Out of warranty.csv" -NoTypeInformation -Append

$popup = New-Object -ComObject Wscript.Shell

$popup.Popup("$firstname $lastname's damage has been logged",0,"Success",1+4096)

$Form.Close()

}

#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '370,50'
$Form.text                       = "Student Damage Log"
$Form.TopMost                    = $True
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("Student Damage Log.exe")
$Form.StartPosition              = "CenterScreen"

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Damage Type"
$ComboBox2.width                 = 130
$ComboBox2.height                = 30
@('LCD Damage', 'Upper Case', 'Lower Case', 'Top Case', 'LCD Bezel', 'Other') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$combobox2.sorted                = $false
$ComboBox2.location              = New-Object System.Drawing.Point(150,14)
$ComboBox2.Font                  = 'Microsoft Sans Serif,10'

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.width                   = 60
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(300,11)
$Button2.Font                    = 'Microsoft Sans Serif,10'
$Button2.Add_Click({ExportCSV})
$Button2.Enabled                 = $false
$Button2.text                    = "Submit"

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
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button2.Enabled = $true}})

$Form.controls.AddRange(@($ComboBox2,$ComboBox1,$Button2))

#Write your logic code here

[void]$Form.ShowDialog()

