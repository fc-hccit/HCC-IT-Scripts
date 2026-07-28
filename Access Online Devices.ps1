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

$Button1.text = "Offline"
$ListBox1.BackColor = "#d0021b"
Start-Sleep 2
$ListBox1.BackColor = "#d0021b"
$Button1.text = "Reload"}
}

Function Search {

$ListBox1.Items.Clear()

$Button1.text = "Searching..."

$Selection = $ComboBox1.SelectedItem.ToString()

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

$computers = (Get-ADComputer -Filter * -SearchBase $OU).Name

$OnlineComputers = $computers | Test-Online | ? OnlineStatus -eq $true

ForEach($computer in $OnlineComputers) {

$LoggedOnUser = Get-WmiObject -ComputerName $computer -Class Win32_Computersystem | Select-Object UserName

if(($LoggedOnUser) -eq $null) {

$User = "Offline"

$listbox1.Items.Add("$User - $computer")

}

elseif(($LoggedOnUser) -like "@{UserName=}") {

$User = "Not Logged In"

$listbox1.Items.Add("$User - $computer")

}

else {

$Domain,$User = $LoggedOnUser.Username.split('\',2)

$listbox1.Items.Add("$User - $computer")

}
}
$Button1.text = "Reload" 
}



Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '330,690'
$Form.text                       = "Access Online Device Shares"
$Form.TopMost                    = $true
$Form.StartPosition             = 'CenterScreen'
$Icon                            = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.Icon                       = $Icon

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 310
$ListBox1.height                 = 580
$ListBox1.location               = New-Object System.Drawing.Point(10,20)
$listBox1.Add_DoubleClick({Open-Share})

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "comboBox"
$ComboBox1.DropDownStyle         = 'DropDownList'
$ComboBox1.AutoSize              = $true
$ComboBox1.width                 = 150
$ComboBox1.height                = 20
$ComboBox1.location              = New-Object System.Drawing.Point(80,605)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({if($S1YR.SelectedIndex -ne "-1") {$Button1.Enabled = $true;$Button1.text = "Search"}})
@('Year 6','Year 7','Year 8','Year 9','Year 10','Year 11','Year 12','Staff Laptops','Staff Desktops') | ForEach-Object {[void] $ComboBox1.Items.Add($_)}

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Search"
$Button1.width                   = 100
$Button1.height                  = 40
$Button1.location                = New-Object System.Drawing.Point(110,640)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Enabled                 = $false
$Button1.Add_Click({Search})

$Form.controls.AddRange(@($ListBox1,$ComboBox1,$Button1))

#Write your logic code here

[void]$Form.ShowDialog()