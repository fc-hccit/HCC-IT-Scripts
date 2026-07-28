$ComputerModel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Model).Model
$SerialNumber = (Get-WmiObject -Class Win32_BIOS | Select-Object SerialNumber).SerialNumber
$SerialNumber = $SerialNumber.substring($SerialNumber.length-5)
$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment

# Aspire V5-473

if ($ComputerModel -like "Aspire V5*")
{$OSDComputerName = "AV5-" + $SerialNumber}

# HP ProBook 430 G2

elseif ($ComputerModel -like "HP ProBook 430*")
{$OSDComputerName = "HP430G2-" + $SerialNumber}

# Spin SP513

elseif ($ComputerModel -like "Spin SP513*")
{$OSDComputerName = "ASPIN-" + $SerialNumber}

# Switch SA5

elseif ($ComputerModel -like "Switch SA5*")
{$OSDComputerName = "ASWITCH-" + $SerialNumber}

# TMP455-MG

elseif ($ComputerModel -like "TMP455-MG*")
{$OSDComputerName = "AP455-" + $SerialNumber}

# TravelMate P238

elseif ($ComputerModel -like "TravelMate P238*")
{$OSDComputerName = "AP238-" + $SerialNumber}

# TravelMate P246

elseif ($ComputerModel -like "TravelMate P246*")
{$OSDComputerName = "AP246-" + $SerialNumber}

# TravelMate P259

elseif ($ComputerModel -like "TravelMate P259*")
{$OSDComputerName = "AP259-" + $SerialNumber}

# TravelMate P449

elseif ($ComputerModel -like "TravelMate P449*")
{$OSDComputerName = "AP449-" + $SerialNumber}

# TravelMate X3410

elseif ($ComputerModel -like "TravelMate X3410*")
{$OSDComputerName = "AX3410-" + $SerialNumber}

# TravelMate X349

elseif ($ComputerModel -like "TravelMate X349*")
{$OSDComputerName = "AX349-" + $SerialNumber}

# Veriton L4610

elseif ($ComputerModel -like "Veriton L4610*")
{$OSDComputerName = "AL4610-" + $SerialNumber}

# Veriton L4620

elseif ($ComputerModel -like "Veriton L4620*")
{$OSDComputerName = "AL4620-" + $SerialNumber}

# Veriton N4640G

elseif ($ComputerModel -like "Veriton N4640G*")
{$OSDComputerName = "AN4640-" + $SerialNumber}

# Other

else { Write-Host "Unknown Computer"}


# Set OSD Name

$TSEnv.Value("OSDComputerName") = "$OSDComputerName"