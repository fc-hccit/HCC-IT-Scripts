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

else {
$popup = New-Object -ComObject Wscript.Shell
$popup.Popup("Device is now offline!",0,"Error",0+0)

$Button1.text = "Reload"}
}

function Update-ProgressBar {
    param (
        [int]$Current,
        [int]$Total
    )
    $percentage = ($Current / $Total) * 100
    $progressBar.Value = $percentage
    $form.Refresh()
}

Function Search {

$ListBox1.Items.Clear()

$Button1.text = "Searching..."

$Selection = $ComboBox1.SelectedItem.ToString()

$Filepath = $TextBox1.Text

$LogDir = "c:\users\$env:USERNAME\desktop"

$cmtrace = "C:\Program Files (x86)\ConfigMgr 2012 Toolkit R2\ClientTools\CMTrace.exe"

if($CheckBox1.Checked -eq $true ){if(test-path "$LogDir\Filecheck.log"){start $cmtrace "$LogDir\Filecheck.log" ; remove-item "$LogDir\Filecheck.log"}}

Write-Host $selection

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


ForEach($computer in $OnlineComputers) {

$LoggedOnUser = Get-WmiObject -ComputerName $computer -Class Win32_Computersystem -ErrorAction SilentlyContinue | Select-Object UserName

$currentItem++

if(($LoggedOnUser) -like "@{UserName=}") {

$User = "Not Logged In"

$listbox1.Items.Add("$User - $computer")

}

else {

if($LoggedOnUser){

$Domain,$User = $LoggedOnUser.Username.split('\',2)

$listbox1.Items.Add("$User - $computer")

if($CheckBox1.Checked -eq $true ){

if (test-path "\\$computer\c$\$filepath"){
$FV = (Get-Item -path "\\$computer\c$\$filepath").VersionInfo.FileVersion
"$FV $user $computer" | out-file "$LogDir\Filecheck.log" -append -force}

else { "File does not exist' on $user's $computer" | out-file "$LogDir\Filecheck.log" -append -force}

}

}
}


Update-ProgressBar -Current $currentItem -Total $totalItems

}

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
$Form.ClientSize                 = '330,720'
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
$listBox1.Add_DoubleClick({Open-Share})
$listBox1.ContextMenuStrip = $contextMenuStrip1
$listBox1.Add_MouseClick({param($sender,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right){
        if ($listBox1.FocusedItem.GetBounds(
            [System.Windows.Forms.ItemBoundsPortion]::Entire).Contains($e.Location)){
            $contextMenuStrip1.Show([System.Windows.Forms.Cursor]::Position)
        }
    } 
})

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.DropDownStyle         = 'DropDownList'
$ComboBox1.AutoSize              = $true
$ComboBox1.width                 = 150
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(80,540)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({if($S1YR.SelectedIndex -ne "-1") {$Button1.Enabled = $true;$Button1.text = "Search"}})
@('Year 6','Year 7','Year 8','Year 9','Year 10','Year 11','Year 12','Staff Laptops','Staff Desktops','TRT Laptops') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 280
$TextBox1.height                 = 20
$TextBox1.Enabled                 = $false
$TextBox1.location               = New-Object System.Drawing.Point(40,580)
$TextBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$CheckBox1                       = New-Object system.Windows.Forms.CheckBox
$CheckBox1.text                  = "Test Path"
$CheckBox1.AutoSize              = $false
$CheckBox1.width                 = 95
$CheckBox1.height                = 20
$CheckBox1.location              = New-Object System.Drawing.Point(120,610)
$CheckBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$CheckBox1.Add_Click({if($CheckBox1.Checked -eq $true ){$TextBox1.Enabled = $true ; $Button1.text = "Test Path" } else {$TextBox1.Enabled = $false ; $Button1.text = "Search"}})

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "C:\"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(15,582)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)


$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Search"
$Button1.width                   = 100
$Button1.height                  = 40
$Button1.location                = New-Object System.Drawing.Point(110,640)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Enabled                 = $false
$Button1.Add_Click({Search})

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 690)
$progressBar.Size = New-Object System.Drawing.Size(310, 20)

$Form.controls.AddRange(@($ListBox1,$ComboBox1,$Button1,$TextBox1,$CheckBox1,$Label1,$progressBar))

#Write your logic code here

[void]$Form.ShowDialog()

