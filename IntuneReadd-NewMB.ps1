<#
.SYNOPSIS
    Troubleshoot and recover a Windows laptop after motherboard replacement for Intune, Entra ID, and Autopilot.
.DESCRIPTION
    This script gathers system state, TPM and Azure AD join status, saves the Autopilot hash to C:\HWID\AutopilotHWID.csv,
    and optionally registers the current device hash in Windows Autopilot with explicit administrator approval.
    It is designed to be safe and non-destructive by default.
.NOTES
    Run in an elevated PowerShell session. Use -Mode Diagnostic for read-only checks.
    Use -Mode Register only after reviewing the output and confirming that the current hardware hash is correct.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Diagnostic','Register')]
    [string]$Mode = 'Diagnostic'
)

$HwidFolder = 'C:\HWID'
$HwidFile = Join-Path $HwidFolder 'AutopilotHWID.csv'
$LogFile = Join-Path $HwidFolder 'RecoveryLog.txt'

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = "$timestamp [$Level] $Message"
    Add-Content -Path $LogFile -Value $entry -ErrorAction SilentlyContinue
}

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'
    )
    switch ($Level) {
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        'WARN'  { Write-Host $Message -ForegroundColor Yellow }
        default { Write-Host $Message -ForegroundColor Cyan }
    }
    Write-Log -Message $Message -Level $Level
}

function Ensure-Administrator {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        Write-Status 'Administrator privileges are required. Re-run this script from an elevated PowerShell session.' 'ERROR'
        throw 'Administrator privileges required.'
    }
}

function Ensure-HwidFolder {
    if (-not (Test-Path -Path $HwidFolder)) {
        try {
            New-Item -Path $HwidFolder -ItemType Directory -Force | Out-Null
            Write-Status "Created folder $HwidFolder"
        } catch {
            Write-Status "Failed to create $($HwidFolder): $_" 'ERROR'
            throw
        }
    }
}

function Get-DsRegStatus {
    $status = @{ AzureAdJoined = 'Unknown'; DomainJoined = 'Unknown'; DeviceAuthStatus = 'Unknown'; AzureAdPrt = 'Unknown'; RawOutput = '' }
    try {
        $raw = & dsregcmd.exe /status 2>&1 | Out-String
        $status.RawOutput = $raw.Trim()
        foreach ($line in $raw -split "`r?`n") {
            if ($line -match '^(AzureAdJoined|DomainJoined|DeviceAuthStatus|AzureAdPrt)\s*:\s*(.+)$') {
                $status[$matches[1]] = $matches[2].Trim()
            }
        }
    } catch {
        Write-Status "Unable to run dsregcmd.exe: $_" 'WARN'
    }
    return $status
}

function Test-InternetConnectivity {
    $results = [ordered]@{
        DnsResolution = $false
        HttpConnectivity = $false
        GraphEndpoint = $false
    }
    try {
        Resolve-DnsName -Name 'www.microsoft.com' -ErrorAction Stop | Out-Null
        $results.DnsResolution = $true
    } catch {
        Write-Log 'DNS resolution for www.microsoft.com failed.'
    }
    try {
        $results.HttpConnectivity = Test-NetConnection -ComputerName 'www.microsoft.com' -Port 443 -InformationLevel Quiet
    } catch {
        Write-Log 'HTTPS connectivity test to www.microsoft.com failed.'
    }
    try {
        $results.GraphEndpoint = Test-NetConnection -ComputerName 'graph.microsoft.com' -Port 443 -InformationLevel Quiet
    } catch {
        Write-Log 'HTTPS connectivity test to graph.microsoft.com failed.'
    }
    return $results
}

function Try-ImportModule {
    param(
        [string]$ModuleName
    )
    if (Get-Module -ListAvailable -Name $ModuleName) {
        try {
            Import-Module -Name $ModuleName -ErrorAction Stop
            Write-Status "Imported module $ModuleName"
            return $true
        } catch {
            Write-Status "Module $ModuleName exists but could not be imported: $_" 'WARN'
            return $false
        }
    }
    return $false
}

function Try-InstallModule {
    param(
        [string]$ModuleName
    )
    try {
        Write-Status "Attempting to install PowerShell module $ModuleName from PSGallery..."
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        Write-Status "Installed module $ModuleName"
        return $true
    } catch {
        Write-Status "Unable to install module $($ModuleName): $_" 'WARN'
        return $false
    }
}

function Get-AutopilotHardwareHash {
    if (-not (Try-ImportModule -ModuleName 'WindowsAutopilotIntune')) {
        if ($internetConnectivity.HttpConnectivity) {
            if (-not (Try-InstallModule -ModuleName 'WindowsAutopilotIntune')) {
                Write-Status 'Cannot install WindowsAutopilotIntune module. Hardware hash collection may be unavailable.' 'WARN'
                return $null
            }
            Try-ImportModule -ModuleName 'WindowsAutopilotIntune' | Out-Null
        } else {
            Write-Status 'No internet connection available to install WindowsAutopilotIntune module.' 'WARN'
            return $null
        }
    }

    if (-not (Get-Command -Name Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
        Write-Status 'Get-WindowsAutopilotInfo is not available even after importing WindowsAutopilotIntune.' 'WARN'
        return $null
    }

    try {
        Write-Status "Collecting Autopilot hardware hash to $HwidFile"
        Get-WindowsAutopilotInfo -OutputFile $HwidFile -ErrorAction Stop
        if (Test-Path -Path $HwidFile) {
            Write-Status "Saved Autopilot hardware hash to $HwidFile"
            return $HwidFile
        }
        Write-Status 'Autopilot hash command completed but file was not created.' 'WARN'
    } catch {
        Write-Status "Failed to collect Autopilot hardware hash: $_" 'WARN'
    }
    return $null
}

function Get-GraphConnection {
    param(
        [string[]]$Scopes
    )

    $requiredGraphModules = @(
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.DeviceManagement'
    )

    foreach ($module in $requiredGraphModules) {
        if (-not (Try-ImportModule -ModuleName $module)) {
            if ($internetConnectivity.HttpConnectivity) {
                if (-not (Try-InstallModule -ModuleName $module)) {
                    Write-Status "Cannot install module $module. Graph queries are unavailable." 'WARN'
                    return $false
                }
                Try-ImportModule -ModuleName $module | Out-Null
            } else {
                Write-Status 'No internet connection available to install required Microsoft.Graph modules.' 'WARN'
                return $false
            }
        }
    }

    try {
        Write-Status "Connecting to Microsoft Graph with scopes: $($Scopes -join ', ')"
        Connect-MgGraph -Scopes $Scopes -ErrorAction Stop | Out-Null
        Write-Status 'Connected to Microsoft Graph.'
        return $true
    } catch {
        Write-Status "Microsoft Graph authentication failed: $_" 'WARN'
        return $false
    }
}

function Query-AutopilotRegistration {
    param(
        [string]$SerialNumber,
        [string]$HardwareHash
    )
    $result = @{ Registered = $false; Devices = @(); Error = $null }
    if (-not $graphAvailable) {
        $result.Error = 'Microsoft Graph is not available.'
        return $result
    }
    try {
        if ($SerialNumber) {
            $filter = [System.Uri]::EscapeDataString("serialNumber eq '$SerialNumber'")
            $uri = "/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=$filter"
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            if ($response.value) {
                $result.Registered = $true
                $result.Devices = $response.value
                return $result
            }
        }

        if ($HardwareHash) {
            $filterHash = [System.Uri]::EscapeDataString("hardwareIdentifier eq '$HardwareHash'")
            $uriHash = "/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=$filterHash"
            $responseHash = Invoke-MgGraphRequest -Method GET -Uri $uriHash -ErrorAction Stop
            if ($responseHash.value) {
                $result.Registered = $true
                $result.Devices = $responseHash.value
                return $result
            }
        }
    } catch [System.Management.Automation.MethodInvocationException] {
        if ($_.Exception.InnerException -and $_.Exception.InnerException.Response.StatusCode -eq 404) {
            $result.Error = 'Graph endpoint returned NotFound for Autopilot device query.'
        } else {
            $result.Error = $_.Exception.Message
        }
    } catch {
        $result.Error = $_.Exception.Message
    }
    return $result
}

function Register-AutopilotHash {
    param(
        [string]$SerialNumber,
        [string]$Manufacturer,
        [string]$Model,
        [string]$HardwareHash,
        [string]$DisplayName
    )
    if (-not $graphAvailable) {
        throw 'Microsoft Graph is not available for registration.'
    }

    $payload = @{
        serialNumber = $SerialNumber
        manufacturer = $Manufacturer
        model = $Model
        hardwareIdentifier = $HardwareHash
        groupTag = 'Replaced-Motherboard'
        displayName = $DisplayName
    }

    try {
        Write-Status 'Registering the current hardware hash in Windows Autopilot...'
        $jsonBody = $payload | ConvertTo-Json -Depth 5
        $result = Invoke-MgGraphRequest -Method POST -Uri '/deviceManagement/windowsAutopilotDeviceIdentities' -Body $jsonBody -ErrorAction Stop
        Write-Status 'Registration request completed.'
        return $result
    } catch {
        Write-Status "Autopilot registration failed: $_" 'ERROR'
        return $null
    }
}

Ensure-Administrator
Ensure-HwidFolder
Write-Status "Starting Autopilot recovery script in $Mode mode."
Write-Status "Log path: $LogFile"
Write-Status "Hardware hash output path: $HwidFile"

$computerName = $env:COMPUTERNAME
$os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
$bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction SilentlyContinue
$system = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
$baseboard = Get-CimInstance -ClassName Win32_BaseBoard -ErrorAction SilentlyContinue

$deviceInfo = [ordered]@{
    ComputerName = $computerName
    WindowsVersion = if ($os) { "$($os.Caption) $($os.Version) (Build $($os.BuildNumber))" } else { 'Unavailable' }
    BIOSVendor = $bios.Manufacturer
    BIOSVersion = if ($bios.SMBIOSBIOSVersion) { ($bios.SMBIOSBIOSVersion -join ', ') } else { 'Unavailable' }
    BIOSReleaseDate = if ($bios.ReleaseDate) { $bios.ReleaseDate } else { 'Unavailable' }
    Model = if ($system) { $system.Model } else { 'Unavailable' }
    Manufacturer = if ($system) { $system.Manufacturer } else { 'Unavailable' }
    SerialNumber = if ($bios) { ($bios.SerialNumber -replace '\s+', '') } else { 'Unavailable' }
    BaseBoardManufacturer = if ($baseboard) { $baseboard.Manufacturer } else { 'Unavailable' }
    BaseBoardProduct = if ($baseboard) { $baseboard.Product } else { 'Unavailable' }
}

foreach ($key in $deviceInfo.Keys) {
    Write-Status "$key : $($deviceInfo[$key])"
}

$tpmStatus = [ordered]@{ Present = 'Unknown'; Version = 'Unknown'; Ready = 'Unknown'; Status = 'Unknown'; Enabled = 'Unknown'; Activated = 'Unknown' }
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpmStatus.Present = $tpm.TpmPresent
    $tpmStatus.Version = $tpm.SpecVersion
    $tpmStatus.Ready = $tpm.TpmReady
    $tpmStatus.Status = $tpm.TpmStatus
    $tpmStatus.Enabled = $tpm.IsEnabled
    $tpmStatus.Activated = $tpm.IsActivated
} catch {
    $tpmStatus.Status = 'Unavailable or not supported'
    Write-Status "Unable to read TPM status: $_" 'WARN'
}
foreach ($key in $tpmStatus.Keys) {
    Write-Status "TPM $key : $($tpmStatus[$key])"
}

$dsreg = Get-DsRegStatus
Write-Status "AzureAdJoined : $($dsreg.AzureAdJoined)"
Write-Status "DomainJoined : $($dsreg.DomainJoined)"
Write-Status "DeviceAuthStatus : $($dsreg.DeviceAuthStatus)"
Write-Status "AzureAdPrt : $($dsreg.AzureAdPrt)"

$internetConnectivity = Test-InternetConnectivity
Write-Status "DNS resolution to www.microsoft.com: $($internetConnectivity.DnsResolution)"
Write-Status "HTTPS connectivity to www.microsoft.com: $($internetConnectivity.HttpConnectivity)"
Write-Status "HTTPS connectivity to graph.microsoft.com: $($internetConnectivity.GraphEndpoint)"

$hashFile = Get-AutopilotHardwareHash
$hardwareHash = $null
if ($hashFile -and (Test-Path -Path $hashFile)) {
    try {
        $csv = Import-Csv -Path $hashFile -ErrorAction Stop
        if ($csv.Count -gt 0) {
            $properties = $csv[0].PSObject.Properties.Name
            $hashProperty = $properties | Where-Object {
                $_ -match '(?i)hardware\s*hash|hardwarehash|hardwareIdentifier|hardwareidentifier'
            } | Select-Object -First 1
            if ($hashProperty) {
                $hardwareHash = $csv[0].$hashProperty
                Write-Status "Current hardware hash was read from $hashFile using column '$hashProperty'"
            } else {
                Write-Status "Hardware hash CSV was created but did not include an expected hash column. Columns: $($properties -join ', ')" 'WARN'
                Write-Status 'Raw CSV preview:'
                Get-Content -Path $hashFile -TotalCount 5 -ErrorAction SilentlyContinue | ForEach-Object { Write-Status "  $_" }
            }
        } else {
            Write-Status "Hardware hash CSV is empty: $hashFile" 'WARN'
            Get-Content -Path $hashFile -TotalCount 5 -ErrorAction SilentlyContinue | ForEach-Object { Write-Status "  $_" }
        }
    } catch {
        Write-Status "Unable to read Autopilot hash CSV: $_" 'WARN'
    }
} else {
    Write-Status 'Autopilot hardware hash was not collected.' 'WARN'
}

$graphAvailable = $false
$autopilotRegistration = @{ Registered = $false; Devices = @(); Error = $null }
if ($internetConnectivity.HttpConnectivity) {
    $graphAvailable = Get-GraphConnection -Scopes @(
        'Device.ReadWrite.All',
        'DeviceManagementServiceConfig.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All',
        'Directory.AccessAsUser.All'
    )
    if ($graphAvailable) {
        $autopilotRegistration = Query-AutopilotRegistration -SerialNumber $deviceInfo.SerialNumber -HardwareHash $hardwareHash
        if ($autopilotRegistration.Registered) {
            Write-Status 'Autopilot registration found for the current device.'
            foreach ($device in $autopilotRegistration.Devices) {
                Write-Status "Autopilot device identity: Id=$($device.id), serial=$($device.serialNumber), manufacturer=$($device.manufacturer), model=$($device.model), groupTag=$($device.groupTag), isAssigned=$($device.isAssigned)"
            }
        } elseif ($autopilotRegistration.Error) {
            Write-Status "Autopilot Graph query error: $($autopilotRegistration.Error)" 'WARN'
        } else {
            Write-Status 'No Autopilot registration was found for the current serial number or hash.'
        }
    } else {
        Write-Status 'Skipping Graph queries because Graph authentication is unavailable.' 'WARN'
    }
} else {
    Write-Status 'Skipping Graph queries because internet connectivity is not available.' 'WARN'
}

if ($Mode -eq 'Register') {
    if (-not $hardwareHash) {
        Write-Status 'Registration mode requires a collected hardware hash. Aborting registration.' 'ERROR'
    } elseif (-not $graphAvailable) {
            $graphAvailable = Get-GraphConnection -Scopes @(
                'Device.ReadWrite.All',
                'DeviceManagementServiceConfig.ReadWrite.All',
                'DeviceManagementManagedDevices.ReadWrite.All',
                'Directory.AccessAsUser.All'
            )
        if ($confirmation -eq 'YES') {
            $displayName = "$computerName-Replacement"
            $registrationResult = Register-AutopilotHash -SerialNumber $deviceInfo.SerialNumber -Manufacturer $deviceInfo.Manufacturer -Model $deviceInfo.Model -HardwareHash $hardwareHash -DisplayName $displayName
            if ($registrationResult) {
                Write-Status 'Autopilot registration was requested. Review the returned object and Intune portal for the new device.'
            } else {
                Write-Status 'Autopilot registration did not complete successfully.' 'ERROR'
            }
        } else {
            Write-Status 'Registration aborted by administrator.' 'WARN'
        }
    }
}

Write-Status '=== Recovery Summary ==='
Write-Status "Mode: $Mode"
Write-Status "ComputerName: $computerName"
Write-Status "WindowsVersion: $($deviceInfo.WindowsVersion)"
Write-Status "Model: $($deviceInfo.Model)"
Write-Status "SerialNumber: $($deviceInfo.SerialNumber)"
Write-Status "TPM Present: $($tpmStatus.Present)"
Write-Status "TPM Ready: $($tpmStatus.Ready)"
Write-Status "AzureAdJoined: $($dsreg.AzureAdJoined)"
Write-Status "DomainJoined: $($dsreg.DomainJoined)"
Write-Status "DeviceAuthStatus: $($dsreg.DeviceAuthStatus)"
Write-Status "AzureAdPrt: $($dsreg.AzureAdPrt)"
Write-Status "Internet HTTP: $($internetConnectivity.HttpConnectivity)"
Write-Status "Graph reachable: $($internetConnectivity.GraphEndpoint)"
$hashFileStatus = if ($hashFile) { $hashFile } else { 'Not collected' }
Write-Status "Hardware hash file: $hashFileStatus"
Write-Status "Autopilot registration status: $([bool]$autopilotRegistration.Registered)"
if ($autopilotRegistration.Error) { Write-Status "Graph query error: $($autopilotRegistration.Error)" 'WARN' }

Write-Status 'Recommended next actions:'
if (-not $hardwareHash) {
    Write-Status '- Collect the Autopilot hardware hash from the running Windows installation first.'
}
if ($dsreg.AzureAdJoined -ne 'YES') {
    Write-Status '- Verify the device is Azure AD joined or that enrollment state is recoverable from the existing installation.'
}
if ($autopilotRegistration.Registered) {
    Write-Status '- Existing Autopilot registration was found. Do not delete it automatically. Review the device identity in Intune/Autopilot.'
} else {
    Write-Status '- If registration mode was not run, use Register mode only after confirming the current hash is correct and the old Autopilot record is retained until the new device is visible.'
}
if ($Mode -ne 'Register') {
    Write-Status '- The script is running in Diagnostic mode by default. Re-run with -Mode Register to attempt Autopilot registration after review.'
}
Write-Status "Script completed at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
