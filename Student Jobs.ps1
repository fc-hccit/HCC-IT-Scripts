Function jobs {
if (-not (Get-Process -Name "student jobs monitor" -ErrorAction SilentlyContinue)) {$Label1.ForeColor='red';$Label1.text = "Monitor not Running" }
$Date = Get-Date -format "dd-MM-yyyy hh.mm"
$ComboBox1.items.clear()
$jobs = Get-ChildItem -path $jobspath
ForEach ($job in $jobs) {$ComboBox1.Items.Add($job)}

}

Function inprogressmail {

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "$stafffirst.$stafflast@hopecc.sa.edu.au" -Subject "$studentname IT Update" -Body "Hi $stafffirst, `n`nThis is an update regarding $studentname's IT issue.`n`n$updatetext. `n`n$loandevicegiven." -SmtpServer "aspmx.l.google.com"

}
Function completedmail {

Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "$stafffirst.$stafflast@hopecc.sa.edu.au" -Subject "$studentname IT Update" -Body "Hi $stafffirst, `n`n$studentname's IT issue has been resolved.`n`n$updatetext." -SmtpServer "aspmx.l.google.com"

}

Function AddDevice { 

$User = $studentname
$Global:LoanDevice = $ComboBox2.SelectedItem.ToString()
    $LogonWorkstations = Get-ADUser -Identity $user -Properties LogonWorkstations | select -ExpandProperty LogonWorkstations #get current computernames that user can access
    if ($LogonWorkstations) {
        $existingWorkstations = $LogonWorkstations -split ',' | Where-Object {$_ -notlike "HCCLOAN*" -and $_ -notlike "ACERL4620*" -and $_ -notlike "HCC-D*"} | ForEach-Object { $_.Trim() } | Select-Object -Unique
        $NewLogonWorkstations = $existingWorkstations + ($NewWorkstation | Where-Object { $existingWorkstations -notcontains $_ }) #add new workstations that are not already in the list
        $NewLogonWorkstationjoined = ($NewLogonWorkstations -join ',')
        Set-ADUser -Identity $User -LogonWorkstations "$NewLogonWorkstationjoined,$LoanDevice" -verbose #set the new list of workstations
        $notification.ShowBalloonTip(5000, "$loandevice checked out to $user", [System.Windows.Forms.ToolTipIcon]::Info)}
    else { 
        Set-ADUser -Identity $User -LogonWorkstations $LoanDevice -verbose #only add new workstations
    }
}




#Variable
$jobspath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs"
$completedjobs = "\\hopecc.sa.edu.au\Source\Files\Completed Student Jobs"
$Date = Get-Date -format "dd-MM-yyyy hh.mm"
$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.Visible = $true

$jobs = Get-ChildItem -path $jobspath

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
$ComboBox1.DrawMode = [System.Windows.Forms.DrawMode]::OwnerDrawFixed
$ComboBox1.Add_DrawItem({
    
 param(
    [System.Object] $sender, 
    [System.Windows.Forms.DrawItemEventArgs] $e
    )
    
    If ($Sender.Items.Count -eq 0) {return}
    
    Try {

        #get current item
        $lbItem=$Sender.Items[$e.Index]
        Write-Host $lbItem
         
        #calculate text colour conditionally
        If ($lbItem -like "*L*_*") {$textColor = [System.Drawing.Color]::Red}

        ElseIf ($lbItem -like "#*") {$textColor = [System.Drawing.Color]::Coral}
        
        Else {$textColor = [System.Drawing.Color]::Green}
       


        #now calculate background color

        $backgroundColor = if(($e.State -band [System.Windows.Forms.DrawItemState]::Selected) -eq [System.Windows.Forms.DrawItemState]::Selected){ 
             #if item is in focus fill with whitesmoke
             [System.Drawing.Color]::AntiqueWhite
        }else{
            #if item not in focus

            #if we want static background color for all rows
            #[System.Drawing.Color]::White

            #or if we want alternating row colors etc

            if($e.Index % 2 -eq 0){
                [System.Drawing.Color]::White
            }else{
                [System.Drawing.Color]::Snow
            }
        }

        #create brushes
        $BackgroundColorBrush = New-Object System.Drawing.SolidBrush($backgroundColor)
        $TextColourBrush = New-Object System.Drawing.SolidBrush($textColor)
        
        #nice smooth rendering of fonts
        $e.Graphics.TextRenderingHint = 'AntiAlias'
        
        #default font
        #$font = $e.Font
        
        #or specify a custom font
        $font = New-Object System.Drawing.Font('Tahoma',10)
              
        # Draw the background
        $e.Graphics.FillRectangle($BackgroundColorBrush, $e.Bounds)
        
        # Draw the text
        $e.Graphics.DrawString($lbItem, $font, $TextColourBrush, (new-object System.Drawing.PointF($e.Bounds.X, $e.Bounds.Y)))
       
        #we decide not to draw the dotted focus triangle
        #$e.DrawFocusRectangle()
    }
    Catch {
        write-host $_.Exception
    }
    Finally {
        $TextColourBrush.Dispose()
         $BackgroundColorBrush.Dispose()
         
         
    }


})


ForEach ($job in $jobs) {$ComboBox1.Items.Add($job)}

$ComboBox1.add_SelectedIndexChanged({
if ($ComboBox1.selectedindex -ne -1){
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
$global:studentname = $firstlinesplitspace[2]
$ListBox1.Text = $jobdetails -join "`n"
$ListBox2.Clear()
}})


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Completed"
$Button1.width                   = 90
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(178,450)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({
$Date = Get-Date -format "dd-MM-yyyy hh.mm"
$logname = $ComboBox1.text
$updatetext = $ListBox2.Text
Write-Output  "$date $updatetext" | Out-File $jobspath\$logname  -Append
Move-Item -Path $jobspath\$logname -Destination "$completedjobs\$logname"
completedmail
$ListBox1.Clear()
$ListBox2.Text = "Saved"
$Button1.Enabled = $false
$Button2.Enabled = $false
$ComboBox1.selectedindex = -1
jobs
})

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "In Progress"
$Button2.width                   = 90
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(43,450)
$Button2.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button2.Add_Click({
$Date = Get-Date -format "dd-MM-yyyy hh.mm"
$logname = $ComboBox1.text
$updatetext = $ListBox2.Text
if($CheckBox1.CheckState -eq $True){AddDevice}
if($CheckBox1.CheckState -eq $True){$Global:loandevicegiven = "$studentfirst was given loan device $loandevice until their laptop is repaired"}
if($CheckBox1.CheckState -eq $True){Write-Output "$date $updatetext Loan device given: $loandevice" | Out-File $jobspath\$logname -Append 

if($loandevice -like "*HCCLOAN10*"){Rename-Item -Path $jobspath\$logname -newname "L10_$logname"}
if($loandevice -like "*HCCLOAN11*"){Rename-Item -Path $jobspath\$logname -newname "L11_$logname"}
if($loandevice -like "*HCCLOAN12*"){Rename-Item -Path $jobspath\$logname -newname "L12_$logname"}
if($loandevice -like "*HCCLOAN13*"){Rename-Item -Path $jobspath\$logname -newname "L13_$logname"}
if($loandevice -like "*HCCLOAN14*"){Rename-Item -Path $jobspath\$logname -newname "L14_$logname"}
if($loandevice -like "*HCCLOAN15*"){Rename-Item -Path $jobspath\$logname -newname "L15_$logname"}
if($loandevice -like "*HCCLOAN2*"){Rename-Item -Path $jobspath\$logname -newname "L02_$logname"}
if($loandevice -like "*HCCLOAN3*"){Rename-Item -Path $jobspath\$logname -newname "L03_$logname"}
if($loandevice -like "*HCCLOAN4*"){Rename-Item -Path $jobspath\$logname -newname "L04_$logname"}
if($loandevice -like "*HCCLOAN5*"){Rename-Item -Path $jobspath\$logname -newname "L05_$logname"}
if($loandevice -like "*HCCLOAN6*"){Rename-Item -Path $jobspath\$logname -newname "L06_$logname"}
if($loandevice -like "*HCCLOAN7*"){Rename-Item -Path $jobspath\$logname -newname "L07_$logname"}
if($loandevice -like "*HCCLOAN8*"){Rename-Item -Path $jobspath\$logname -newname "L08_$logname"}
if($loandevice -like "*HCCLOAN9*"){Rename-Item -Path $jobspath\$logname -newname "L09_$logname"}
if($loandevice -like "*HCCLOAN1*"){Rename-Item -Path $jobspath\$logname -newname "L01_$logname"}
}

else {
Write-Output $jobspath
Write-Output $logname
Write-Output "$date $updatetext" | Out-File $jobspath\$logname -Append
Rename-Item "$jobspath\$logname" "#$logname"
}

inprogressmail
$CheckBox1.checked = $false
$ComboBox1.selectedindex = -1
$ComboBox2.selectedindex = -1
$ComboBox2.Enabled = $false
$ListBox1.Clear()
$ListBox2.Text = "Saved"
$Button2.Enabled = $false
$Button1.Enabled = $false
jobs
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
$CheckBox1.location              = New-Object System.Drawing.Point(59,390)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox1.Add_Click({
if($CheckBox1.CheckState -eq $True){$ComboBox2.Enabled = $true}
if($CheckBox1.CheckState -eq $false) {$ComboBox2.Enabled = $false}})

$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Select"
$ComboBox2.width                 = 100
$ComboBox2.height                = 20
$ComboBox2.location              = New-Object System.Drawing.Point(166,388)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$ComboBox2.Enabled               = $false
@('HCCLOAN1','HCCLOAN2','HCCLOAN3','HCCLOAN4','HCCLOAN5','HCCLOAN6','HCCLOAN7','HCCLOAN8','HCCLOAN9','HCCLOAN10','HCCLOAN11','HCCLOAN12','HCCLOAN13','HCCLOAN14','HCCLOAN15') | ForEach-Object {[void] $ComboBox2.Items.Add($_)}

$Label1                         = New-Object system.Windows.Forms.Label
$Label1.width                   = 200
$Label1.height                  = 30
$Label1.location                = New-Object System.Drawing.Point(100,420)
$Label1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)



if (-not (Get-Process -Name "student jobs monitor" -ErrorAction SilentlyContinue)) {Start-Process ".\Student Jobs monitor.exe";$Label1.ForeColor='green';$Label1.text = "Monitor Running" }
else{$Label1.ForeColor='green';$Label1.text = "Monitor Running"}


$Form.controls.AddRange(@($ComboBox1,$ComboBox2,$Button1,$Button2,$ListBox1,$ListBox2,$Button3,$CheckBox1,$label1))

[void]$Form.ShowDialog()