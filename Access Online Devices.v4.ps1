function Test-Online {
	<#
	.SYNOPSIS
	Test for connection status for one or more computers
	.DESCRIPTION
	Tests one or more computers for network connection. Two NoteProperties are added to the object(s) on their way through the pipeline:
		* OnlineStatus - will be $true if the computer is online, $false otherwise
		* IPV4Address - the IP address of the computer, if any
	Note this Cmdlet uses parallel processing techniques to test many computers at once, so results are returned very quickly, even for a large number of input objects.
	.PARAMETER Property
	The name of a property of InputObject that contains the name of the computer; required if InputObject is anything other than a string.
	.PARAMETER InputObject
	One or more objects to test for network connection
	.EXAMPLE
	'Computer1','Computer2' | Test-Online -Property Name | ? OnlineStatus -eq $true

	Tests 2 computers (named Computer1 and Computer2) and sends the names of those that are on the network down the pipeline.
	.INPUTS
	PSObject or string.
	.OUTPUTS
	Same as input, with two additional properties appended
	.NOTES
	Author: Dale Thompson
	LastEdit: 09/24/14
	#Requires -Version 2.0
	#>
	[CmdletBinding(DefaultParameterSetName = 'ByString')]
	Param (
		[Parameter(Mandatory,ValueFromPipeline)] $InputObject,
		[Parameter(ParameterSetName='NotString',Mandatory,Position=0)]
			[ValidateNotNullOrEmpty()] [string] $Property
	)
	BEGIN {
		$Jobs = @{}
		$MaxJobs = 50
		$ProcessJobs = {
			Start-Sleep -Milliseconds 200
			$Keys = ($Jobs.Keys).Clone()
			foreach ($j in $Keys) {
				if ($Jobs[$j].State -eq 'Completed') {
					$Status = $false; $IPV4Address = '0.0.0.0'
					$Jobs[$j] | Receive-Job | ? StatusCode -eq 0 | Select-Object -First 1 | % {
						$x = $_
						$Status = $true
						$IPV4Address = try { $_.IPV4Address.PSObject.Properties | ? Name -eq 'IPAddressToString' | Select-Object -ExpandProperty Value } catch { $x.Address }
					}
					$Jobs[$j].InputObject | Add-Member -Force -PassThru -NotePropertyMembers @{
						OnlineStatus = $Status
						IPV4Address = $IPV4Address
					}
					try { Remove-Job $Jobs[$j]; $Jobs.Remove($j) } catch {}
				}
			}
		}
	}
	PROCESS {
		while ($Jobs.Count -gt $MaxJobs) { . $ProcessJobs }
		$CompName = switch ($PSCmdlet.ParameterSetName) {
			'ByString' { $InputObject.ToString() }
			'NotString' { $InputObject | Select-Object -Property $Property | % { $_.$Property } }
		}
		if ($CompName) {
			$Job = Test-Connection -Count 3 -ComputerName $CompName -AsJob -EA SilentlyContinue | Add-Member -NotePropertyName InputObject -NotePropertyValue $InputObject -PassThru
			try {
				$Jobs.Add($CompName, $Job)
			} catch {
				Stop-Job $Job
				Remove-Job $Job
			}
		} else {
			$InputObject | Add-Member -Force -PassThru -NotePropertyMembers @{
				OnlineStatus = $false
				IPV4Address = '0.0.0.0'
			}
		}
	}
	END { while ($Jobs.Count -gt 0) { . $ProcessJobs } }
}

Function Open-Share {

$ListSelect = $listBox1.SelectedItem.ToString()

$ListUser,$ListComputer = $ListSelect.split('-',2).trim()

if((Test-Connection $ListComputer -Count 1 -Quiet ) -eq $true) {Start \\$ListComputer\C$}

else {[System.Windows.Forms.MessageBox]::Show("Device is now offline!", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)

$Button1.text = "Reload"}
}

function Update-ProgressBar {
    param (
        [int]$Current,
        [int]$Total
    )
    $percentage = ($Current / $TotalItems) * 100
    $progressBar.Value = $percentage
    $form.Refresh()
}

Function Search {

$ListBox1.Items.Clear()

$Button1.text = "Searching..."

$progressBar.Value = 0

$Selection = $ComboBox1.SelectedItem.ToString()

$Filepath = $TextBox1.Text

$LogDir = "c:\users\$env:USERNAME\desktop"

$cmtrace = "C:\Program Files (x86)\ConfigMgr 2012 Toolkit R2\ClientTools\CMTrace.exe"

if($CheckBox1.Checked -eq $true ){if(test-path "$LogDir\Filecheck.log"){start $cmtrace "$LogDir\Filecheck.log" ; remove-item "$LogDir\Filecheck.log"}}

if (($Selection) -eq "Year 6") {$OU = "OU=Year 6,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 7") {$OU = "OU=Year 7,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 8") {$OU = "OU=Year 8,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 9") {$OU = "OU=Year 9,OU=Middle,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 10") {$OU = "OU=Year 10,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 11") {$OU = "OU=Year 11,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Year 12") {$OU = "OU=Year 12,OU=Senior,OU=Student,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Staff Laptops") {$OU = "OU=Staff,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "Staff Desktops") {$OU = "OU=Staff,OU=Desktops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}
elseif (($Selection) -eq "TRT Desktops") {$OU = "OU=TRT,OU=Laptops,OU=Devices,DC=hopecc,DC=sa,DC=edu,DC=au"}

$computers = (Get-ADComputer -Filter * -SearchBase $OU).Name 

$OnlineComputers = $computers | Test-Online | ? OnlineStatus -eq $true 

$totalItems = $OnlineComputers.Count

$currentItem = 0

ForEach($OnlineComputer in $OnlineComputers
) {

$LoggedOnUser = Get-WmiObject -ComputerName $OnlineComputer -Class Win32_Computersystem -ErrorAction SilentlyContinue | Select-Object UserName

$currentItem++


if(($LoggedOnUser) -like "@{UserName=}") {

$User = "Not Logged In"

$listbox1.Items.Add("$User - $computer")

}

Else{

if(!($LoggedOnUser -eq $Null)){

$Domain,$User = $LoggedOnUser.Username.split('\',2)

$listbox1.Items.Add("$User - $OnlineComputer")

if($CheckBox1.Checked -eq $true ){
$Button1.text = "Testing..."
if (test-path "\\$OnlineComputer\c$\$filepath"){
$FV = (Get-Item -path "\\$OnlineComputer\c$\$filepath").VersionInfo.FileVersion
$DM = (Get-Item -path "\\$OnlineComputer\c$\$filepath").LastWriteTime
"$DM $FV $user $OnlineComputer" | out-file "$LogDir\Filecheck.log" -append -force}

else { "File does not exist' on $user's $OnlineComputer" | out-file "$LogDir\Filecheck.log" -append -force}

}


if ($CheckBox2.Checked -eq $true) {
$Button1.text = "Replacing..."
    try {
        Copy-Item -Path $Global:SelectedLocalFile -Destination "\\$OnlineComputer\c$\$Filepath" -Force -ErrorAction Stop
        "Copyd $user $($OnlineComputer)" | Out-File "$LogDir\Filecheck.log" -Append -Force
    } catch {
       "Error occurred while copying file to $($OnlineComputer): $_" | Out-File "$LogDir\Filecheck.log" -Append -Force
    }
}

elseif ($CheckBox3.Checked -eq $true) {
$Button1.text = "Deleting..."
    try {
        Remove-Item -Path $Global:SelectedLocalFile -Destination "\\$OnlineComputer\c$\$Filepath" -Force -ErrorAction Stop
        "Deleted $user $($OnlineComputer)" | Out-File "$LogDir\Filecheck.log" -Append -Force
    } catch {
       "Error occurred while deleting file on $($OnlineComputer): $_" | Out-File "$LogDir\Filecheck.log" -Append -Force
    }
}

Update-ProgressBar -Current $currentItem -Total $totalItems

}
}
}
$progressBar.Value = 100
$Button1.text = "Reload"
}

Function Restart {
$ListSelect = $listBox1.SelectedItem.ToString()
$ListUser,$ListComputer = $ListSelect.split('-',2).trim()
if((Test-Connection $ListComputer -Count 1 -Quiet ) -eq $true) {
shutdown /r /m \\$ListComputer /t 300 /c "The IT Department has initiated a remote restart on your computer! `nYour Computer will restart in 5 Minutes, Please save your work!"}
}

Function RemoteCmd {
$ListSelect = $listBox1.SelectedItem.ToString()
$ListUser,$ListComputer = $ListSelect.split('-',2).trim()
if((Test-Connection $ListComputer -Count 1 -Quiet ) -eq $true) {
start-process cmd /c "c:\engineer\psexec \\$ListComputer cmd"}
}


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '330,750'
$Form.text                       = "Access Online Device Shares"
$Form.TopMost                    = $true
$Form.StartPosition              = 'CenterScreen'
$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon                       = $Icon

$contextMenuStrip1               = New-Object System.Windows.Forms.ContextMenuStrip
$contextMenuStrip1.Items.Add("Restart")
$contextMenuStrip1.Items.Add("RemoteCmd")
$contextMenuStrip1.Items[0].Add_Click({Restart})
$contextMenuStrip1.Items[1].Add_Click({RemoteCmd})

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.Sorted                 = $true
$ListBox1.width                  = 310
$ListBox1.height                 = 500
$ListBox1.location               = New-Object System.Drawing.Point(10,20)
$ListBox1.Add_DoubleClick({Open-Share})
$ListBox1.ContextMenuStrip = $contextMenuStrip1
$ListBox1.Add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
        $index = $ListBox1.IndexFromPoint($e.Location)
        if ($index -ge 0 -and $index -eq $ListBox1.SelectedIndex) {
            $contextMenuStrip1.Show($ListBox1, $e.Location)
        }
    }
})

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.DropDownStyle         = 'DropDownList'
$ComboBox1.AutoSize              = $true
$ComboBox1.width                 = 150
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(80,530)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({if($S1YR.SelectedIndex -ne "-1") {$Button1.Enabled = $true}})
@('Year 6','Year 7','Year 8','Year 9','Year 10','Year 11','Year 12','Staff Laptops','Staff Desktops','TRT Laptops') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 280
$TextBox1.height                 = 20
$TextBox1.Enabled                 = $false
$TextBox1.location               = New-Object System.Drawing.Point(40,570)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Test Path"
$CheckBox1.AutoSize              = $true
$CheckBox1.location              = New-Object System.Drawing.Point(20,605)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox1.Add_Click({if($CheckBox1.Checked -eq $true ){$TextBox1.Enabled = $true ; $Button1.text = "Test Path" } else {$TextBox1.Enabled = $false ; $Button1.text = "Search"}})

# New Checkbox for Replacing File
$CheckBox2                       = New-Object system.Windows.Forms.CheckBox
$CheckBox2.text                  = "Copy"
$CheckBox2.AutoSize              = $true
$CheckBox2.location              = New-Object System.Drawing.Point(130,605)
$CheckBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox2.Add_Click({if($CheckBox2.Checked -eq $true ){$Button2.Enabled = $true ;$CheckBox3.Checked = $false; $TextBox1.Enabled = $true ; $Button1.text = "Copy File"} else {$TextBox1.Enabled = $false ; $Button2.Enabled = $false ; $Button1.text = "Search"}})

# New Checkbox for Deleting File
$CheckBox3                       = New-Object system.Windows.Forms.CheckBox
$CheckBox3.text                  = "Delete"
$CheckBox3.AutoSize              = $true
$CheckBox3.location              = New-Object System.Drawing.Point(230,605)
$CheckBox3.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox3.Add_Click({if($CheckBox3.Checked -eq $true ){$TextBox1.Enabled = $true ;$CheckBox2.Checked = $false; $Button1.text = "Delete File"} else {$TextBox1.Enabled = $false ; $Button2.Enabled = $false ; $Button1.text = "Search"}})


# New Button for File Selection
$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Select File"
$Button2.width                   = 100
$Button2.height                  = 30
$Button2.location                = New-Object System.Drawing.Point(15,630)
$Button2.Font                    = 'Microsoft Sans Serif,8'
$Button2.Enabled                 = $false
$Button2.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:SelectedLocalFile = $openFileDialog.FileName
        $SelectedLocalFilename = Split-Path $SelectedLocalFile -leaf
        $Label2.Text = "$SelectedLocalFilename"
}
})

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "C:\"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(14,572)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "No file selected"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(130,635)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',8)

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Search"
$Button1.width                   = 150
$Button1.height                  = 40
$Button1.location                = New-Object System.Drawing.Point(90,670)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Enabled                 = $false
$Button1.Add_Click({Search})

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 720)
$progressBar.Size = New-Object System.Drawing.Size(310, 20)

$Form.controls.AddRange(@($ListBox1,$ComboBox1,$Button1,$TextBox1,$CheckBox1,$CheckBox2,$CheckBox3,$Button2,$Label1,$Label2,$progressBar))

#Write your logic code here

[void]$Form.ShowDialog()
