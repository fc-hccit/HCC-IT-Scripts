
Function Validate{
if ($ComboBox1.SelectedIndex -eq "-1") { $ErrorProvider.SetError($ComboBox1, "Please select your name") } 
elseif ($ComboBox2.SelectedIndex -eq "-1") { $ErrorProvider.SetError($ComboBox2, "Please select your issue") }
elseif ($ComboBox3.SelectedIndex -eq "-1") { $ErrorProvider.SetError($ComboBox3, "Please select your teacher") }
else {Submit;$Form.Close()}
}

Function Submit{
$issue = $combobox2.Text
# Student
$studentname = $combobox1.text.Split(".")
$studentfirst = $studentname[0]
$studentlast = $studentname[1]
# Staff
$staffname = $combobox3.text.Split(" ")
$stafflast = $staffname[0]
$stafflastbracket = $staffname[1]
$stafffirst = $stafflastbracket.trim('()')

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "$stafffirst.$stafflast@hopecc.sa.edu.au" -Subject "$studentfirst $studentlast checked into the IT Office" -Body "Hi $stafffirst, `n`n$studentfirst $studentlast just checked into the IT Office with the following issue: $issue.`n`nWe will send them back to class as soon as possible and update you concerning the outcome." -SmtpServer "aspmx.l.google.com"

$Date = Get-Date -format "dd-M-yyyy hh.mm"
$logpath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs"
$donepath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs\Done\$studentname.log"
$Log = "\\hopecc.sa.edu.au\Source\Files\Student Jobs\$Date $Studentname.log"

Write-Output  "$Date $studentname $issue @$stafffirst.$stafflast"| Out-File -Append $Log

}

$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.Clear() 

#Get Users

$Students = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName
$Teachers = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Teaching,OU=Staff,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(600,560)
$Form.text                       = "IT Checkin"
$Form.TopMost                    = $true
$Form.StartPosition              = "manual"
$form.Location                   = New-Object System.Drawing.Size(650,70)
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("C:\kiosk\checkin.exe")


$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 400
$ComboBox1.height                = 30
$ComboBox1.location              = New-Object System.Drawing.Point(100,140)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'      

ForEach($Student in $Students) {
$Name = $Student.Split(".")
$studentfirst = $Name[0]
$studentlast = $Name[1]
$combobox1.Items.Add($Student)}


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Submit"
$Button1.width                   = 100
$Button1.height                  = 50
$Button1.location                = New-Object System.Drawing.Point(250,480)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',12,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$Button1.Add_Click({Validate})



$ComboBox2                       = New-Object system.Windows.Forms.ListBox
$ComboBox2.text                  = "Issue"
$ComboBox2.width                 = 400
$ComboBox2.height                = 200
$ComboBox2.location              = New-Object System.Drawing.Point(100,200)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
@('Laptop damaged or faulty','Network or internet connectivity problem','Login issue','Lost or misplaced laptop','Charger or bag missing or damaged','Software issue','Blacklisted','Laptop collection') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}
$combobox2.sorted                = $true

$ComboBox3                       = New-Object system.Windows.Forms.ComboBox
$ComboBox3.text                  = "Teacher"
$ComboBox3.width                 = 400
$ComboBox3.height                = 44
$ComboBox3.location              = New-Object System.Drawing.Point(100,420)
$ComboBox3.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',14)
$combobox3.sorted                = $true
$combobox3.AutoCompleteMode      = 'Suggest'
$combobox3.AutoCompleteSource    = 'ListItems'

ForEach($Teacher in $Teachers) {
$Name = $teacher.Split(".")
$teacherfirst = $Name[0]
$teacherlast = $Name[1]
$combobox3.Items.Add("$teacherlast ($teacherfirst)")
}


$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Welcome to the IT Office"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(120,30)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft YaHei',20,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Please fill in the details below"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(110,90)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft YaHei',18,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$Form.controls.AddRange(@($ComboBox1,$Button1,$ComboBox2,$ComboBox3,$Label1,$Label2))


#region Logic 

#endregion

[void]$Form.ShowDialog()