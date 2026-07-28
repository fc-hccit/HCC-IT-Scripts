#Functions

function Send-Email {

Send-MailMessage -From 'CCTV Monitoring <alerts@hopecc.sa.edu.au>' -To 'CCTV Authorisation Manager <businessmanager@hopecc.sa.edu.au>' -Subject "CCTV Access Report by $Firstname $Lastname " -Body "Hi Tim,`n`n$Firstname $Lastname is reviewing the following incident`n`nDate on Incident: $doi`n`nTime of Incident: $toi`n`nLocation of incident: $loi`n`nNature of Occurence: `n`n$noc`n`nPurpose of request:`n`n$por " -SmtpServer 'aspmx.l.google.com' 
Send-MailMessage -From 'CCTV Monitoring <alerts@hopecc.sa.edu.au>' -To $useremail -Subject "Your CCTV access has been recorded" -Body "Hi $Firstname,`nYour CCTV access has been recorded and relevent personell have been notified of the following details as per the CCTV Policy and CCTV Terms of use.`n`nDate on Incident: $doi`n`nTime of Incident: $toi`n`nLocation of incident:  $loi`n`nNature of Occurence: `n`n$noc`n`nPurpose of request:`n`n$por" -SmtpServer 'aspmx.l.google.com'

Run-CCTV

} 


function Grab-Info {

$doi = $DateTimePicker1.Text
$toi = $DateTimePicker2.Text
$loi = $TextBox1.Text
$noc = $RichTextBox1.Text
$por = $RichTextBox2.Text

$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
$ErrorProvider.Clear() 
if ($TextBox1.Text.Length -eq 0) { $ErrorProvider.SetError($TextBox1, "Please enter a location") } 
elseif ($RichTextBox1.Text.Length -lt 10) { $ErrorProvider.SetError($RichTextBox1, "Please enter more details about the nature of occurence. ") }
elseif ($RichTextBox2.Text.Length -lt 10) { $ErrorProvider.SetError($RichTextBox2, "Please enter more details about the purpose of the request. ") }
else {Send-Email;$Form1.Close()}

}

function Run-CCTV { 

Rename-Item -Path "c:\Users\Public\iVMS\iVMS-4200 Client\Program.dll" -NewName "iVMS-4200.exe"

."c:\Users\Public\iVMS\iVMS-4200 Client\iVMS-4200.exe"

Rename-Item -Path "c:\Users\Public\iVMS\iVMS-4200 Client\iVMS-4200.exe" -NewName "Program.dll"}

function Show-Form {

$Form1 = New-Object -TypeName System.Windows.Forms.Form
[System.Windows.Forms.Label]$Label1 = $null
[System.Windows.Forms.Label]$Label2 = $null
[System.Windows.Forms.Label]$Label3 = $null
[System.Windows.Forms.Label]$Label4 = $null
[System.Windows.Forms.Label]$Label5 = $null
[System.Windows.Forms.DateTimePicker]$DateTimePicker1 = $null
[System.Windows.Forms.DateTimePicker]$DateTimePicker2 = $null
[System.Windows.Forms.TextBox]$TextBox1 = $null
[System.Windows.Forms.RichTextBox]$RichTextBox1 = $null
[System.Windows.Forms.RichTextBox]$RichTextBox2 = $null
[System.Windows.Forms.Button]$Button1 = $null
$CenterScreen = [System.Windows.Forms.FormStartPosition]::CenterScreen;
$form1.StartPosition = $CenterScreen;

$Label1 = (New-Object -TypeName System.Windows.Forms.Label)
$Label2 = (New-Object -TypeName System.Windows.Forms.Label)
$Label3 = (New-Object -TypeName System.Windows.Forms.Label)
$Label4 = (New-Object -TypeName System.Windows.Forms.Label)
$Label5 = (New-Object -TypeName System.Windows.Forms.Label)
$DateTimePicker1 = (New-Object -TypeName System.Windows.Forms.DateTimePicker)
$DateTimePicker2 = (New-Object -TypeName System.Windows.Forms.DateTimePicker)
$TextBox1 = (New-Object -TypeName System.Windows.Forms.TextBox)
$RichTextBox1 = (New-Object -TypeName System.Windows.Forms.RichTextBox)
$RichTextBox2 = (New-Object -TypeName System.Windows.Forms.RichTextBox)
$Button1 = (New-Object -TypeName System.Windows.Forms.Button)
$Form1.SuspendLayout()
#
#Label1
#
$Label1.FlatStyle = [System.Windows.Forms.FlatStyle]::Popup
$Label1.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Label1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]184,[System.Int32]32))
$Label1.Name = [System.String]'Label1'
$Label1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]154,[System.Int32]19))
$Label1.TabIndex = [System.Int32]0
$Label1.Text = [System.String]'Time of Incident'
$Label1.UseCompatibleTextRendering = $true
$Label1.add_Click($Label1_Click)
#
#Label2
#
$Label2.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Label2.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]35,[System.Int32]32))
$Label2.Name = [System.String]'Label2'
$Label2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]120,[System.Int32]23))
$Label2.TabIndex = [System.Int32]1
$Label2.Text = [System.String]'Date of Incident'
$Label2.UseCompatibleTextRendering = $true
$Label2.add_Click($Label2_Click)
#
#Label3
#
$Label3.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Label3.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]344,[System.Int32]32))
$Label3.Name = [System.String]'Label3'
$Label3.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]143,[System.Int32]23))
$Label3.TabIndex = [System.Int32]2
$Label3.Text = [System.String]'Location of Incident'
$Label3.UseCompatibleTextRendering = $true
#
#Label4
#
$Label4.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Label4.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]25,[System.Int32]102))
$Label4.Name = [System.String]'Label4'
$Label4.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]175,[System.Int32]24))
$Label4.TabIndex = [System.Int32]3
$Label4.Text = [System.String]'Nature of Occurence'
$Label4.UseCompatibleTextRendering = $true
#
#Label5
#
$Label5.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Label5.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]25,[System.Int32]298))
$Label5.Name = [System.String]'Label5'
$Label5.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]156,[System.Int32]22))
$Label5.TabIndex = [System.Int32]4
$Label5.Text = [System.String]'Purpose of Request'
$Label5.UseCompatibleTextRendering = $true
#
#DateTimePicker1
#
$DateTimePicker1.AllowDrop = $true
$DateTimePicker1.Format = [System.Windows.Forms.DateTimePickerFormat]::Short
$DateTimePicker1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]35,[System.Int32]58))
$DateTimePicker1.Name = [System.String]'DateTimePicker1'
$DateTimePicker1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]111,[System.Int32]21))
$DateTimePicker1.TabIndex = [System.Int32]5
#
#DateTimePicker2
#
$DateTimePicker2.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
$DateTimePicker2.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]184,[System.Int32]58))
$DateTimePicker2.Name = [System.String]'DateTimePicker2'
$DateTimePicker2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]122,[System.Int32]21))
$DateTimePicker2.TabIndex = [System.Int32]6
#
#TextBox1
#
$TextBox1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]327,[System.Int32]58))
$TextBox1.Name = [System.String]'TextBox1'
$TextBox1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]160,[System.Int32]21))
$TextBox1.TabIndex = [System.Int32]7
#
#RichTextBox1
#
$RichTextBox1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]25,[System.Int32]129))
$RichTextBox1.Name = [System.String]'RichTextBox1'
$RichTextBox1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]462,[System.Int32]166))
$RichTextBox1.TabIndex = [System.Int32]8
$RichTextBox1.Text = [System.String]''
#
#RichTextBox2
#
$RichTextBox2.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]25,[System.Int32]323))
$RichTextBox2.Name = [System.String]'RichTextBox2'
$RichTextBox2.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]462,[System.Int32]177))
$RichTextBox2.TabIndex = [System.Int32]9
$RichTextBox2.Text = [System.String]''
#
#Button1
#
$Button1.Font = (New-Object -TypeName System.Drawing.Font -ArgumentList @([System.String]'Tahoma',[System.Single]9.75,[System.Drawing.FontStyle]::Bold,[System.Drawing.GraphicsUnit]::Point,([System.Byte][System.Byte]0)))
$Button1.Location = (New-Object -TypeName System.Drawing.Point -ArgumentList @([System.Int32]184,[System.Int32]536))
$Button1.Name = [System.String]'Button1'
$Button1.Size = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]131,[System.Int32]43))
$Button1.TabIndex = [System.Int32]10
$Button1.Text = [System.String]'Submit'
$Button1.UseCompatibleTextRendering = $true
$Button1.UseVisualStyleBackColor = $true
$Button1.Enabled = $true
$Button1.add_Click({Grab-Info})
#
#Form1
#
$Form1.ClientSize = (New-Object -TypeName System.Drawing.Size -ArgumentList @([System.Int32]516,[System.Int32]602))
$Form1.Controls.Add($Button1)
$Form1.Controls.Add($RichTextBox2)
$Form1.Controls.Add($RichTextBox1)
$Form1.Controls.Add($TextBox1)
$Form1.Controls.Add($DateTimePicker2)
$Form1.Controls.Add($DateTimePicker1)
$Form1.Controls.Add($Label5)
$Form1.Controls.Add($Label4)
$Form1.Controls.Add($Label3)
$Form1.Controls.Add($Label2)
$Form1.Controls.Add($Label1)
$Form1.TopMost = $true
$Form1.ResumeLayout($false)
$Form1.PerformLayout()
Add-Member -InputObject $Form1 -Name base -Value $base -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Label1 -Value $Label1 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Label2 -Value $Label2 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Label3 -Value $Label3 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Label4 -Value $Label4 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Label5 -Value $Label5 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name DateTimePicker1 -Value $DateTimePicker1 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name DateTimePicker2 -Value $DateTimePicker2 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name TextBox1 -Value $TextBox1 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name RichTextBox1 -Value $RichTextBox1 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name RichTextBox2 -Value $RichTextBox2 -MemberType NoteProperty
Add-Member -InputObject $Form1 -Name Button1 -Value $Button1 -MemberType NoteProperty

Add-Type -AssemblyName System.Windows.Forms
$Form1.ShowDialog()

}

#Variables

$Username = $env:UserName
$First,$Last = $env:UserName.Split(".")
$Firstname = ( Get-Culture ).TextInfo.ToTitleCase( $First.ToLower() )
$Lastname = ( Get-Culture ).TextInfo.ToTitleCase( $Last.ToLower() )
$useremail = "$Username@hopecc.sa.edu.au"


#Terms of Use

$confirm = [System.Windows.Forms.MessageBox]::Show("While viewing and saving CCTV footage please be aware of the following restrictions:
`n*Footage will only be viewed when there is a reasonable belief that an incident has occurred and that the data may assist in a resolution
`n*Access to CCTV footage will be generally restricted to those persons who need to have access in order to achieve the purposes of using the CCTV equipment
`n*Disclosure to third parties must be limited to law enforcement agencies, where the footage may assist in a specific or criminal enquiry, or be required for legal representation, in accordance with the procedure set out in this policy
`n*All access to the medium on which the footage is recorded will be documented on the CCTV Request form.
`n*Footage (or any images acquired by HCC) will not be made more widely available (e.g. given to the media or placed on the internet/social media) without the correct permissions or at the discretion of the Principal in consultation with the AISSA legal advice
`n*Footage will be not made available to any parent of the College community unless summoned/subpoenaed (and footage that involves children other than their own must also be applied for with a formal FOI application.)
`n
`n DO YOU AGREE TO THESE TERMS?
", 'Please Confirm', 'YesNo', 'Warning')

if ($confirm -eq 'Yes') {Show-Form}


