# Load configuration from the config file
$configPath = "C:\Users\ITMGR-ND\Desktop\hccagentconfig.txt"
$config = @{}

# Read and parse the config file
Get-Content $configPath | ForEach-Object {
    $line = $_.Trim()

    # Skip empty lines or comments (if you have comments starting with #)
    if ($line -eq "" -or $line.StartsWith("#")) { return }

    # Split each line at the first "=" and add to the config hashtable
    $key, $value = $line -split "=", 2
    $key = $key.Trim()
    $value = $value.Trim().Trim("'") # Remove any surrounding quotes

    # Add to the config hashtable
    $config[$key] = $value
}

# Function to convert boolean fields
function Convert-ToBoolean ($value) {
    return $value -eq "true"
}

# Convert specific fields to booleans
$config["AlertOnFileFailure1"] = Convert-ToBoolean($config["AlertOnFileFailure1"])
$config["AlertOnFileFailure2"] = Convert-ToBoolean($config["AlertOnFileFailure2"])
$config["AlertOnRegistryFailure1"] = Convert-ToBoolean($config["AlertOnRegistryFailure1"])

# Email configuration
$emailFrom = "alerts@hopecc.sa.edu.au"
$emailTo = "itstaff@hopecc.sa.edu.au"
$SmtpServer = "aspmx.l.google.com"

# Get the last logged-on user
$unkey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
$LastLoggedOnUser = (Get-ItemProperty -Path $unkey -Name LastLoggedOnUser).LastLoggedOnUser
$usernamesplit = $LastLoggedOnUser.split("\")
$username = if ($usernamesplit.Count -gt 1) { $usernamesplit[1] } else { $LastLoggedOnUser }

# Get the device name
$devicename = $env:ComputerName

# Function to check file existence and version
function Check-Files {
    param (
        [array]$fileEntries
    )
    $alerts = @()
    foreach ($entry in $fileEntries) {
        $checkName = $entry.CheckName
        $filePath = $entry.FilePath
        $expectedVersion = $entry.ExpectedFileVersion
        $alertOnFailure = $entry.AlertOnFileFailure
        
        if (Test-Path $filePath) {
            $fileVersion = (Get-Item $filePath).VersionInfo.FileVersion
            if ($fileVersion -ne $expectedVersion -and $alertOnFailure) {
                $alerts += "[$devicename - $username] $checkName`: File version mismatch for $filePath"
            }
        } elseif ($alertOnFailure) {
            $alerts += "[$devicename - $username] $checkName`: File not found: $filePath"
        }
    }
    return $alerts
}

# Function to check registry key and value
function Check-Registry {
    param (
        [array]$registryEntries
    )
    $alerts = @()
    foreach ($entry in $registryEntries) {
        $checkName = $entry.CheckName
        $keyPath = $entry.RegistryPath
        $valueName = $entry.RegistryValueName
        $expectedValue = $entry.ExpectedRegistryValue
        $alertOnFailure = $entry.AlertOnRegistryFailure
        
        $value = Get-ItemProperty -Path $keyPath -Name $valueName -ErrorAction SilentlyContinue
        if ($null -eq $value -and $alertOnFailure) {
            $alerts += "[$devicename - $username] $checkName`: Registry key/value not found: $keyPath\$valueName"
        } elseif ($value.$valueName -ne $expectedValue -and $alertOnFailure) {
            $alerts += "[$devicename - $username] $checkName`: Registry value mismatch for $keyPath\$valueName"
        }
    }
    return $alerts
}

# Function to check service status
function Check-Services {
    param (
        [array]$serviceEntries
    )
    $alerts = @()
    foreach ($entry in $serviceEntries) {
        $checkName = $entry.CheckName
        $serviceName = $entry.ServiceName
        $expectedStatus = $entry.ExpectedServiceStatus
        $alertOnFailure = $entry.AlertOnServiceFailure
        
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -eq $service -and $alertOnFailure) {
            $alerts += "[$devicename - $username] $checkName`: Service not found: $serviceName"
        } elseif ($service.Status -ne $expectedStatus -and $alertOnFailure) {
            $alerts += "[$devicename - $username] $checkName`: Service status mismatch for $serviceName`: expected $expectedStatus, found $($service.Status)"
        }
    }
    return $alerts
}

# Function to report system uptime
function Get-Uptime {
    return (Get-CimInstance -Class Win32_OperatingSystem).LastBootUpTime
}

# Function to send email alerts
function Send-EmailAlert {
    param (
        [string]$message
    )
        Send-MailMessage -From $emailFrom -To $emailTo -Subject "HCC Agent Alert" -Body $message -SmtpServer $smtpServer
         
}

# Main monitoring logic
$alerts = @()

# Check files
if ($config["CheckFileExistence"] -eq "true") {
    $fileEntries = @()
    for ($i = 1; $i -le 10; $i++) { # Adjust upper limit as needed
        if ($config["CheckNameFile$i"] -and $config["FilePath$i"] -and $config["ExpectedFileVersion$i"] -and $config["AlertOnFileFailure$i"]) {
            $fileEntries += [PSCustomObject]@{
                CheckName           = $config["CheckNameFile$i"]
                FilePath            = $config["FilePath$i"]
                ExpectedFileVersion  = $config["ExpectedFileVersion$i"]
                AlertOnFileFailure   = Convert-ToBoolean($config["AlertOnFileFailure$i"])
            }
        }
    }
    if ($fileEntries.Count -gt 0) {
        $alerts += Check-Files -fileEntries $fileEntries
    }
}

# Check registry
if ($config["CheckRegistry"] -eq "true") {
    $registryEntries = @()
    for ($i = 1; $i -le 10; $i++) { # Adjust upper limit as needed
        if ($config["CheckNameRegistry$i"] -and $config["RegistryPath$i"] -and $config["RegistryValueName$i"] -and $config["ExpectedRegistryValue$i"] -and $config["AlertOnRegistryFailure$i"]) {
            $registryEntries += [PSCustomObject]@{
                CheckName             = $config["CheckNameRegistry$i"]
                RegistryPath          = $config["RegistryPath$i"]
                RegistryValueName      = $config["RegistryValueName$i"]
                ExpectedRegistryValue  = $config["ExpectedRegistryValue$i"]
                AlertOnRegistryFailure = Convert-ToBoolean($config["AlertOnRegistryFailure$i"])
            }
        }
    }
    if ($registryEntries.Count -gt 0) {
        $alerts += Check-Registry -registryEntries $registryEntries
    }
}

# Check services
if ($config["CheckServiceStatus"] -eq "true") {
    $serviceEntries = @()
    for ($i = 1; $i -le 10; $i++) { # Adjust upper limit as needed
        if ($config["CheckNameService$i"] -and $config["ServiceName$i"] -and $config["ExpectedServiceStatus$i"] -and $config["AlertOnServiceFailure$i"]) {
            $serviceEntries += [PSCustomObject]@{
                CheckName            = $config["CheckNameService$i"]
                ServiceName          = $config["ServiceName$i"]
                ExpectedServiceStatus = $config["ExpectedServiceStatus$i"]
                AlertOnServiceFailure = Convert-ToBoolean($config["AlertOnServiceFailure$i"])
            }
        }
    }
    if ($serviceEntries.Count -gt 0) {
        $alerts += Check-Services -serviceEntries $serviceEntries
    }
}

# Report uptime if enabled
if ($config["ReportUptime"] -eq "true") {
    $alerts += "[$devicename - $username] System uptime: $(Get-Uptime)"
}

# Send email alert if there are any alerts
if ($alerts.Count -gt 0) {
    Send-EmailAlert -message ($alerts -join "`n")
}
