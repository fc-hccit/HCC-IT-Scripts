function Load-Form {
    $Form.Controls.Add($TBComputerName)
    $Form.Controls.Add($GBComputerName)
    $Form.Controls.Add($ButtonOK)
    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()
}

function Set-OSDComputerName {
    $ErrorProvider.Clear()
    if ($TBComputerName.Text.Length -eq 0) {
        $ErrorProvider.SetError($GBComputerName, "Please enter a computer name")
    }
    else {
        if ($TBComputerName.Text.Length -gt 15) {
            $ErrorProvider.SetError($GBComputerName, "Computer name cannot be more than 15 characters")
        }
        else {
            $global:OSDComputerName = $TBComputerName.Text.Replace("[","").Replace("]","").Replace(":","").Replace(";","").Replace("|","").Replace("=","").Replace("+","").Replace("*","").Replace("?","").Replace("<","").Replace(">","").Replace("/","").Replace("\","").Replace(",","")
             $Form.Close()
             }
    }
}

function Set-Serial {
    $ErrorProvider.Clear()
    if ($TBComputerName.Text.Length -ne 5) {
        $ErrorProvider.SetError($GBComputerName, "Please enter the last 5 characters of the SNID")
    }
    
    else {$global:ISerialNumber = $TBComputerName.Text.Replace("[","").Replace("]","").Replace(":","").Replace(";","").Replace("|","").Replace("=","").Replace("+","").Replace("*","").Replace("?","").Replace("<","").Replace(">","").Replace("/","").Replace("\","").Replace(",","")
          $Form.Close()
        }
    }


[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

$Global:ErrorProvider = New-Object System.Windows.Forms.ErrorProvider

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(285,140)  
$Form.MinimumSize = New-Object System.Drawing.Size(285,140)
$Form.MaximumSize = New-Object System.Drawing.Size(285,140)
$Form.StartPosition = "CenterScreen"
$Form.SizeGripStyle = "Hide"
$Form.Text = "Please enter the last 5 characters of the SNID"
$Form.ControlBox = $false
$Form.TopMost = $true

$TBComputerName = New-Object System.Windows.Forms.TextBox
$TBComputerName.Location = New-Object System.Drawing.Size(25,30) 
$TBComputerName.Size = New-Object System.Drawing.Size(215,50)
$TBComputerName.TabIndex = "1"

$GBComputerName = New-Object System.Windows.Forms.GroupBox
$GBComputerName.Location = New-Object System.Drawing.Size(20,10) 
$GBComputerName.Size = New-Object System.Drawing.Size(225,50) 
$GBComputerName.Text = "SNID:" 

$ButtonOK = New-Object System.Windows.Forms.Button 
$ButtonOK.Location = New-Object System.Drawing.Size(195,70) 
$ButtonOK.Size = New-Object System.Drawing.Size(50,20) 
$ButtonOK.Text = "OK"
$ButtonOK.TabIndex = "2"


# Start Script

$ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model).Model
$SerialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object SerialNumber).SerialNumber
$SerialNumberLength = $SerialNumber.Length
$SerialNumberL5 = $SerialNumber.substring($SerialNumber.length-5)
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Aspire V5-473

if ($ComputerModel -like "Aspire V5*")
{ if ($SerialNumberLength -gt 11) {$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "AV5-" + $ISerialNumber}
  else {$OSDComputerName = "AV5-" + $SerialNumberL5}
}

# HP ProBook 430 G2

elseif ($ComputerModel -like "HP ProBook 430*")
{$OSDComputerName = "HP430G2-" + $SerialNumberL5}

# Spin SP513-54N

elseif ($ComputerModel -like "Spin SP513-54N*")
{$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "ASPIN-" + $ISerialNumber}

# Spin SP513-53N

elseif ($ComputerModel -like "Spin SP513-53N*")
{$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "ASPIN-" + $ISerialNumber}

# Spin SP314

elseif ($ComputerModel -like "Spin SP314*")
{$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "ASPIN-" + $ISerialNumber}

# Veriton Z4860G

elseif ($ComputerModel -like "Z4860G*")
{$OSDComputerName = "AVZ4860G-" + $SerialNumberL5}

# Switch SA5

elseif ($ComputerModel -like "Switch SA5*")
{$OSDComputerName = "ASWITCH-" + $SerialNumberL5}

# Extensa 215

elseif ($ComputerModel -like "Extensa 215*")
{$OSDComputerName = "AEX215-" + $SerialNumberL5}

# TMP455-MG

elseif ($ComputerModel -like "TMP455-MG*")
{$OSDComputerName = "AP455-" + $SerialNumberL5}

# TMP214

elseif ($ComputerModel -like "Travelmate P214*")
{$OSDComputerName = "AP214-" + $SerialNumberL5}

# TMP215

elseif ($ComputerModel -like "Travelmate P215*")
{$OSDComputerName = "AP215-" + $SerialNumberL5}

# TravelMate P238

elseif ($ComputerModel -like "TravelMate P238*")
{ if ($SerialNumberLength -gt 11) {$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "AP238-" + $ISerialNumber}
  else {$OSDComputerName = "AP238-" + $SerialNumberL5}
}

# TravelMate P246

elseif ($ComputerModel -like "TravelMate P246*")
{$OSDComputerName = "AP246-" + $SerialNumberL5}

# TravelMate P259

elseif ($ComputerModel -like "TravelMate P259*")
{$OSDComputerName = "AP259-" + $ISerialNumber5}

# TravelMate P449

elseif ($ComputerModel -like "TravelMate P449*")
{$OSDComputerName = "AP449-" + $SerialNumberL5}

# TravelMate X3410

elseif ($ComputerModel -like "TravelMate X3410*")
{$OSDComputerName = "AX3410-" + $SerialNumberL5}

# TravelMate X314-51

elseif ($ComputerModel -like "TravelMate X314-51*")
{ if ($SerialNumberLength -gt 11) {$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "TMX314-" + $ISerialNumber}
  else {$OSDComputerName = "TMX314-" + $SerialNumberL5}
}


# TravelMate X349

elseif ($ComputerModel -like "TravelMate X349*")
{$ButtonOK.Add_Click({Set-Serial});Load-Form;$OSDComputerName = "AX349-" + $ISerialNumber}

# Veriton L4610

elseif ($ComputerModel -like "Veriton L4610*")
{$OSDComputerName = "AL4610-" + $SerialNumberL5}

# Veriton L4620

elseif ($ComputerModel -like "Veriton L4620*")
{$OSDComputerName = "AL4620-" + $SerialNumberL5}

# Veriton N4640G

elseif ($ComputerModel -like "Veriton N4640G*")
{$OSDComputerName = "AN4640-" + $SerialNumberL5}

# Veriton N4660G

elseif ($ComputerModel -like "Veriton N4660G*")
{$OSDComputerName = "AN4660-" + $SerialNumberL5}

# Other

else { 
$Form.Text = "Please enter computer name"
$GBComputerName.Text = "Computer Name:" 
$ButtonOK.Add_Click({Set-OSDComputerName})
Load-Form
}


# Set OSD Name
$TSEnv.Value("OSDComputerName") = "$global:OSDComputerName"
