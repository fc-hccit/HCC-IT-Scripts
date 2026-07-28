Function jobs {

$ComboBox1.items.clear()
$jobs = Get-ChildItem -path $jobspath
ForEach ($job in $jobs) {$ComboBox1.Items.Add($job)}

}

Function inprogressmail {

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "luke.trollope@hopecc.sa.edu.au" -Subject "$studentfirst $studentlast IT Update" -Body "Hi $stafffirst, `n`nThis is an update regarding $studentfirst $studentlast's IT issue.`n`n$updatetext. `n`n$loandevicegiven." -SmtpServer "aspmx.l.google.com"

}
Function completedmail {

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "luke.trollope@hopecc.sa.edu.au" -Subject "$studentfirst $studentlast IT Update" -Body "Hi $stafffirst, `n`n$studentfirst $studentlast's IT issue has been resolved.`n`n$updatetext." -SmtpServer "aspmx.l.google.com"

}

Function AddDevice { 

$popup = New-Object -ComObject Wscript.Shell
$User = "$studentfirst.$studentlast"
$Global:LoanDevice = $ComboBox2.SelectedItem.ToString()
$LogonWorkstations = Get-AdUser -Identity $user -Properties LogonWorkstations | select -ExpandProperty LogonWorkstations #get current computernames that user can access

if ($LogonWorkstations) {
    Set-ADUser -Identity $User -LogonWorkstations "$LogonWorkstations,$LoanDevice" -verbose #add new workstation to existing entries
}
else { 
    Set-ADUser -Identity $User -LogonWorkstations $LoanDevice -verbose #only add new workstation
}
$popup.Popup("$LoanDevice has been checked out to $user",0,"Success",48+0)
} 


#Variable
$jobspath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs"
$completedjobs = "\\hopecc.sa.edu.au\Source\Files\Completed Student Jobs"
$Date = Get-Date -format "dd-MM-yyyy hh.mm"

$jobs = Get-ChildItem -path $jobspath
ForEach ($job in $jobs) {$ComboBox1.Items.Add($job)}

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(310,500)
$Form.text                       = "Student Jobs"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"
$Form.Icon                       = [system.drawing.icon]::ExtractAssociatedIcon("Student Jobs.exe")

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Open Jobs"
$ComboBox1.width                 = 270
$ComboBox1.height                = 40
$ComboBox1.location              = New-Object System.Drawing.Point(20,11)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
ForEach ($job in $jobs) {$ComboBox1.Items.Add($job)}
$ComboBox1.add_SelectedIndexChanged({
$logname = $ComboBox1.text
$Button1.Enabled = $True
$Button2.Enabled = $True
$jobdetails = Get-Content $jobspath\$logname
$firstline = Get-Content $jobspath\$logname | Select-Object -First 1
$firstlinesplitat = $firstline.split("@")
$staffname = $firstlinesplitat[1]
$stafffirstlast = $staffname.split(".")
$global:stafffirst =  $stafffirstlast[0]
$global:stafflast = $stafffirstlast[1]
$firstlinesplitspace = $firstline.split(" ")
$global:studentfirst = $firstlinesplitspace[2]
$global:studentlast = $firstlinesplitspace[3]
$ListBox1.Text = $jobdetails -join "`n"
$ListBox2.Clear()})


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Completed"
$Button1.width                   = 90
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(178,450)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({
$logname = $ComboBox1.text
$updatetext = $ListBox2.Text
Write-Output  "$date $updatetext" | Out-File $jobspath\$logname  -Append
Move-Item -Path $jobspath\$logname -Destination "$completedjobs\$logname"
completedmail
$ListBox2.Text = "Saved"
$Button1.Enabled = $false
$Button2.Enabled = $false
})

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "In Progress"
$Button2.width                   = 90
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(43,450)
$Button2.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button2.Add_Click({
$logname = $ComboBox1.text
$updatetext = $ListBox2.Text
if($CheckBox1.CheckState -eq $True){AddDevice}
if($CheckBox1.CheckState -eq $True){$Global:loandevicegiven = "$studentfirst was given loan device $loandevice until thier laptop is repaired"}
if($CheckBox1.CheckState -eq $True){Write-Output "$date $updatetext Loan device given: $loandevice" | Out-File $jobspath\$logname  -Append}
else {Write-Output "$date $updatetext" | Out-File $jobspath\$logname  -Append}
inprogressmail
$ListBox2.Text = "Saved"
$Button2.Enabled = $false
$Button1.Enabled = $false
})


$ListBox1                        = New-Object system.Windows.Forms.RichTextBox
$ListBox1.text                   = "No log loaded"
$ListBox1.width                  = 270
$ListBox1.height                 = 134
$ListBox1.location               = New-Object System.Drawing.Point(20,80)


$ListBox2                        = New-Object system.Windows.Forms.RichTextBox
$ListBox2.text                   = "Update log"
$ListBox2.width                  = 270
$ListBox2.height                 = 134
$ListBox2.location               = New-Object System.Drawing.Point(20,240)

$Button3                         = New-Object system.Windows.Forms.Button
$Button3.text                    = "Reload"
$Button3.width                   = 60
$Button3.height                  = 30
$Button3.location                = New-Object System.Drawing.Point(118,43)
$Button3.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button3.Add_Click({jobs})

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Issued loan"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(59,403)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox1.Add_Click({
if($CheckBox1.CheckState -eq $True){$ComboBox2.Enabled = $true}
if($CheckBox1.CheckState -eq $false) {$ComboBox2.Enabled = $false}})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Select"
$ComboBox2.width                 = 100
$ComboBox2.height                = 20
$ComboBox2.location              = New-Object System.Drawing.Point(166,400)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$ComboBox2.Enabled               = $false
@('HCCLOAN1','HCCLOAN2','HCCLOAN3','HCCLOAN4','HCCLOAN5','HCCLOAN6','HCCLOAN7','HCCLOAN8','HCCLOAN9','HCCLOAN10') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}


$Form.controls.AddRange(@($ComboBox1,$ComboBox2,$Button1,$Button2,$ListBox1,$ListBox2,$Button3,$CheckBox1))


#region Logic 

#endregion

[void]$Form.ShowDialog()