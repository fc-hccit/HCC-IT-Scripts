$logDirectory = Join-Path $PSScriptRoot 'Logs'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$logFile = Join-Path $logDirectory ("Delete-ReEnroll-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$moduleCachePath = Join-Path $PSScriptRoot 'Modules'
New-Item -ItemType Directory -Path $moduleCachePath -Force | Out-Null

function Write-BootstrapMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$ForegroundColor = 'Cyan'
    )

    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Write-BootstrapModuleStatus {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$Status,

        [string]$ForegroundColor = 'Cyan',

        [switch]$Complete
    )

    $line = "[Bootstrap] Module {0}: {1}" -f $ModuleName, $Status
    $paddedLine = "{0,-140}" -f $line
    Write-Host ("`r{0}" -f $paddedLine) -NoNewline -ForegroundColor $ForegroundColor

    if ($Complete) {
        Write-Host ""
    }
}

function Ensure-NuGetProvider {
    $provider = Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    if ($provider -and $provider.Version -ge [version]'2.8.5.201') {
        return $true
    }

    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
    }
    catch {
        return $false
    }

    $provider = Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1

    return [bool]($provider -and $provider.Version -ge [version]'2.8.5.201')
}

function Save-ModuleToCache {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$ModuleCacheRoot
    )

    $downloadUri = "https://www.powershellgallery.com/api/v2/package/{0}" -f $ModuleName
    $modulePath = Join-Path $ModuleCacheRoot $ModuleName
    $tempPackagePath = Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-{1}.nupkg" -f $ModuleName, [guid]::NewGuid().ToString('N'))
    $tempExtractPath = Join-Path ([System.IO.Path]::GetTempPath()) ("{0}-{1}" -f $ModuleName, [guid]::NewGuid().ToString('N'))

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $downloadUri -OutFile $tempPackagePath -UseBasicParsing -ErrorAction Stop

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        New-Item -ItemType Directory -Path $tempExtractPath -Force | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($tempPackagePath, $tempExtractPath)

        if (Test-Path $modulePath) {
            Remove-Item -Path $modulePath -Recurse -Force -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Path $modulePath -Force | Out-Null
        Get-ChildItem -Path $tempExtractPath -Force | Move-Item -Destination $modulePath -Force

        return Resolve-ModuleManifestPath -ModuleName $ModuleName -ModuleCacheRoot $ModuleCacheRoot
    }
    finally {
        if (Test-Path $tempPackagePath) {
            Remove-Item -Path $tempPackagePath -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $tempExtractPath) {
            Remove-Item -Path $tempExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-BootstrapMessage -Message "[Bootstrap] Package provider bootstrap will run only if required for missing modules." -ForegroundColor DarkGray
Write-Host ""

try {
    Start-Transcript -Path $logFile -Append -ErrorAction Stop | Out-Null
    Write-Host "Logging to file: $logFile" -ForegroundColor DarkGray
}
catch {
    Write-Host "Warning: Could not start transcript logging. $($_.Exception.Message)" -ForegroundColor Yellow
}

Clear-Host

function Write-StatusLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatusMessage,

        [Parameter(Mandatory = $true)]
        [int]$ElapsedSeconds,

        [string]$ForegroundColor = 'DarkYellow'
    )

    $hours = [int][Math]::Floor($ElapsedSeconds / 3600)
    $minutes = [int][Math]::Floor(($ElapsedSeconds % 3600) / 60)
    $seconds = [int]($ElapsedSeconds % 60)
    $elapsedDisplay = "{0:D2}.{1:D2}.{2:D2}" -f $hours, $minutes, $seconds
    Write-Host ("{0} | Elapsed: {1}" -f $StatusMessage, $elapsedDisplay) -ForegroundColor $ForegroundColor
}

function Write-TaskTimerLine {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StatusMessage,

        [Parameter(Mandatory = $true)]
        [int]$ElapsedSeconds,

        [Parameter(Mandatory = $true)]
        [int]$EstimateSeconds,

        [string]$EstimateDisplay,

        [string]$ForegroundColor = 'DarkYellow',

        [object[]]$Segments,

        [switch]$NewLine
    )

    $elapsedMinutes = [int][Math]::Floor($ElapsedSeconds / 60)
    $elapsedSeconds = [int]($ElapsedSeconds % 60)
    $elapsedDisplay = "{0:D2}:{1:D2}" -f $elapsedMinutes, $elapsedSeconds

    if (-not $EstimateDisplay) {
        $estimateMinutes = [int][Math]::Floor($EstimateSeconds / 60)
        $estimateSeconds = [int]($EstimateSeconds % 60)
        $EstimateDisplay = "{0:D2}:{1:D2}" -f $estimateMinutes, $estimateSeconds
    }

    if ($NewLine) {
        [Console]::WriteLine()
    }

    $linePrefix = if ($Segments -and $Segments.Count -gt 0) {
        ($Segments | ForEach-Object { $_.Text }) -join ''
    }
    else {
        $StatusMessage
    }

    $line = "$linePrefix | $elapsedDisplay/$EstimateDisplay"
    $previousLength = if ($script:LastTimerLineLength) { $script:LastTimerLineLength } else { 0 }
    $padding = if ($line.Length -lt $previousLength) { ' ' * ($previousLength - $line.Length) } else { '' }

    if ($Segments -and $Segments.Count -gt 0) {
        [Console]::Write("`r")
        foreach ($segment in $Segments) {
            Write-Host $segment.Text -NoNewline -ForegroundColor $segment.Color
        }
        Write-Host (" | {0}/{1}{2}" -f $elapsedDisplay, $EstimateDisplay, $padding) -NoNewline -ForegroundColor $ForegroundColor
    }
    else {
        Write-Host ("`r{0}{1}" -f $line, $padding) -NoNewline -ForegroundColor $ForegroundColor
    }

    $script:LastTimerLineLength = $line.Length
}

function Complete-StatusLine {
    Write-Host ""
}

function Get-WaitHistoryRootPath {
    $waitHistoryRoot = Join-Path $PSScriptRoot 'WaitTimeHistory'
    New-Item -ItemType Directory -Path $waitHistoryRoot -Force | Out-Null
    return $waitHistoryRoot
}

function Get-WaitHistoryFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $historyRoot = Get-WaitHistoryRootPath
    return Join-Path $historyRoot ("{0}.txt" -f $TaskName)
}

function Get-WaitHistory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )

    $historyPath = Get-WaitHistoryFilePath -TaskName $TaskName
    if (-not (Test-Path $historyPath)) {
        return @()
    }

    try {
        $lines = Get-Content -Path $historyPath -ErrorAction Stop | Where-Object { $_ -and $_.Trim() }
        return @($lines | ForEach-Object { [int]([double]$_.Trim()) })
    }
    catch {
        return @()
    }
}

function Get-MedianValue {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Values
    )

    $sortedValues = @($Values | Sort-Object)
    if ($sortedValues.Count -eq 0) {
        return $null
    }

    $middleIndex = [int][Math]::Floor($sortedValues.Count / 2)
    if ($sortedValues.Count % 2 -eq 1) {
        return [int]$sortedValues[$middleIndex]
    }

    return [int][Math]::Round((($sortedValues[$middleIndex - 1] + $sortedValues[$middleIndex]) / 2), 0)
}

function Format-EstimatedDuration {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Seconds
    )

    $minutes = [int][Math]::Floor($Seconds / 60)
    $remainingSeconds = [int]($Seconds % 60)
    return "{0}:{1:D2}" -f $minutes, $remainingSeconds
}

function Get-WaitEstimateSummary {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Values
    )

    $sortedValues = @($Values | Sort-Object)
    if ($sortedValues.Count -eq 0) {
        return $null
    }

    $lowerBound = [int]$sortedValues[0]
    $upperBound = [int]$sortedValues[-1]
    $median = Get-MedianValue -Values $sortedValues

    return [pscustomobject]@{
        LowerBound = $lowerBound
        UpperBound = $upperBound
        Median = $median
    }
}

function Save-WaitHistory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [System.Collections.IEnumerable]$Durations
    )

    $historyPath = Get-WaitHistoryFilePath -TaskName $TaskName
    $trimmedDurations = @($Durations | Select-Object -Last 50)

    if ($trimmedDurations.Count -eq 0) {
        if (Test-Path $historyPath) {
            Remove-Item -Path $historyPath -Force -ErrorAction SilentlyContinue
        }
        return
    }

    $trimmedDurations | ForEach-Object { [string][int]$_ } | Set-Content -Path $historyPath -Encoding UTF8
}

function Get-EnrollmentStepKey {
    param(
        [AllowNull()]
        [string]$Status
    )

    switch ($Status) {
        $null { return 'Registration' }
        'notAssigned' { return 'NotAssigned' }
        'pending' { return 'Pending' }
        'assignedUnkownSyncState' { return 'Assigned' }
        'assignedUnknownSyncState' { return 'Assigned' }
        default { return 'Other' }
    }
}

function Test-IsAssignedEnrollmentStatus {
    param(
        [AllowNull()]
        [string]$Status
    )

    if ([string]::IsNullOrWhiteSpace($Status)) {
        return $false
    }

    return $Status.ToLowerInvariant().StartsWith('assigned')
}

function Save-EnrollmentStepDuration {
    param(
        [AllowNull()]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [int]$DurationSeconds,

        [Parameter(Mandatory = $true)]
        [hashtable]$StepHistories
    )

    if ($DurationSeconds -le 0) {
        return
    }

    $stepKey = Get-EnrollmentStepKey -Status $Status
    if (-not $StepHistories.ContainsKey($stepKey)) {
        $StepHistories[$stepKey] = @()
    }

    $StepHistories[$stepKey] += $DurationSeconds
    Save-WaitHistory -TaskName ("Enrollment-{0}" -f $stepKey) -Durations $StepHistories[$stepKey]
}

function Get-EnrollmentStepEstimateSeconds {
    param(
        [AllowNull()]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [hashtable]$StepHistories
    )

    $stepKey = Get-EnrollmentStepKey -Status $Status
    if ($stepKey -eq 'Registration') {
        return 60
    }

    if (-not $StepHistories.ContainsKey($stepKey)) {
        return 180
    }

    $history = @($StepHistories[$stepKey])
    if ($history.Count -eq 0) {
        return 180
    }

    return [int](Get-WaitEstimateSummary -Values $history).Median
}

function Get-EnrollmentStepEstimateDisplay {
    param(
        [AllowNull()]
        [string]$Status,

        [Parameter(Mandatory = $true)]
        [hashtable]$StepHistories,

        [Parameter(Mandatory = $true)]
        [int]$FallbackSeconds
    )

    $stepKey = Get-EnrollmentStepKey -Status $Status
    $history = if ($StepHistories.ContainsKey($stepKey)) { @($StepHistories[$stepKey]) } else { @() }

    if ($history.Count -eq 0) {
        return 'NA'
    }

    return Format-EstimatedDuration -Seconds $FallbackSeconds
}

function Add-CurrentDeviceToAutopilot {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SerialNumber,

        [Parameter(Mandatory = $true)]
        [string]$GroupTag
    )

    if (-not (Get-Command Add-AutopilotImportedDevice -ErrorAction SilentlyContinue)) {
        throw 'WindowsAutopilotIntune is required to import the device into Autopilot.'
    }

    $cimSession = New-CimSession
    try {
        $devDetail = Get-CimInstance -CimSession $cimSession -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'"

        if (-not $devDetail -or -not $devDetail.DeviceHardwareData) {
            throw 'Unable to retrieve device hardware data (hash) from the local computer.'
        }

        Write-Host "Gathering Autopilot import data for serial number: $SerialNumber" -ForegroundColor Cyan
        return Add-AutopilotImportedDevice -serialNumber $SerialNumber -hardwareIdentifier $devDetail.DeviceHardwareData -groupTag $GroupTag
    }
    finally {
        Remove-CimSession $cimSession
    }
}

$banner = @"

██████╗ ███████╗██╗         ██████╗███╗   ███╗██████╗
██╔══██╗██╔════╝██║        ██╔════╝████╗ ████║██╔══██╗
██║  ██║█████╗  ██║        ██║     ██╔████╔██║██║  ██║
██║  ██║██╔══╝  ██║        ██║     ██║╚██╔╝██║██║  ██║
██████╔╝███████╗███████╗   ╚██████╗██║ ╚═╝ ██║██████╔╝
╚═════╝ ╚══════╝╚══════╝    ╚═════╝╚═╝     ╚═╝╚═════╝

Delete & Re-Enroll Tool v2.1
"@

Write-Host $banner -ForegroundColor Cyan

function Read-SingleKeyChoice {
    param(
        [string[]]$ValidKeys
    )

    while ($true) {
        $key = [System.Console]::ReadKey($true).KeyChar.ToString()
        if ($ValidKeys -contains $key) {
            return $key
        }
    }
}

function Resolve-ModuleManifestPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$ModuleCacheRoot
    )

    $moduleNameCandidates = @($ModuleName)
    if ($ModuleName -eq 'WindowsAutopilotIntune') {
        $moduleNameCandidates += 'WindowsAutoPilotIntune'
    }
    elseif ($ModuleName -eq 'WindowsAutoPilotIntune') {
        $moduleNameCandidates += 'WindowsAutopilotIntune'
    }

    foreach ($candidateName in $moduleNameCandidates | Select-Object -Unique) {
        $installedModule = Get-Module -ListAvailable -Name $candidateName -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $candidateName } |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if ($installedModule -and $installedModule.Path) {
            return $installedModule.Path
        }

        $modulePath = Join-Path $ModuleCacheRoot $candidateName
        if (Test-Path $modulePath) {
            $manifest = Get-ChildItem -Path $modulePath -Filter "$candidateName.psd1" -Recurse -File -ErrorAction SilentlyContinue |
                Select-Object -First 1

            if ($manifest) {
                return $manifest.FullName
            }
        }
    }

    return $null
}

# --- INSTALL NUGET ---
$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.DeviceManagement',
    'Microsoft.Graph.Beta.DeviceManagement.Enrollment',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Intune',
    'Microsoft.Graph.Groups',
    'WindowsAutopilotIntune'
)

$bootstrapNeedsModuleInstall = $false
foreach ($module in $requiredModules) {
    $resolvedManifest = Resolve-ModuleManifestPath -ModuleName $module -ModuleCacheRoot $moduleCachePath
    if ($resolvedManifest) {
        continue
    }

    if (-not (Get-Module -ListAvailable -Name $module)) {
        $bootstrapNeedsModuleInstall = $true
        break
    }
}

if ($bootstrapNeedsModuleInstall) {
    Write-BootstrapMessage -Message "[Bootstrap] Required modules are missing; ensuring NuGet provider is available..." -ForegroundColor Cyan
    try {
        $nugetReady = Ensure-NuGetProvider
        if ($nugetReady) {
            Write-BootstrapMessage -Message "[Bootstrap] NuGet provider ready." -ForegroundColor Green
        }
        else {
            Write-BootstrapMessage -Message "[Bootstrap] Warning: NuGet provider install failed; module installation may still fail." -ForegroundColor Yellow
        }
    }
    catch {
        Write-BootstrapMessage -Message ("[Bootstrap] Warning: NuGet provider install failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}
else {
    Write-BootstrapMessage -Message "[Bootstrap] Required modules already available; skipping NuGet provider installation." -ForegroundColor DarkGray
}

# --- INSTALL REQUIRED MODULES IF MISSING ---

if (-not (($env:PSModulePath -split ';') -contains $moduleCachePath)) {
    $env:PSModulePath = "$moduleCachePath;$env:PSModulePath"
}

foreach ($module in $requiredModules) {
    $resolvedManifest = Resolve-ModuleManifestPath -ModuleName $module -ModuleCacheRoot $moduleCachePath

    if ($resolvedManifest) {
        try {
            Write-BootstrapModuleStatus -ModuleName $module -Status 'Loading cached module...' -ForegroundColor Cyan
            Import-Module $resolvedManifest -Force -ErrorAction Stop
            Write-BootstrapModuleStatus -ModuleName $module -Status 'Ready (cached).' -ForegroundColor Green -Complete
            continue
        }
        catch {
            Write-BootstrapModuleStatus -ModuleName $module -Status 'Cached import failed; attempting download...' -ForegroundColor Yellow
        }
    }

    if (-not (Get-Module -ListAvailable -Name $module)) {
        if (-not (Ensure-NuGetProvider)) {
            Write-BootstrapModuleStatus -ModuleName $module -Status 'Missing and NuGet is unavailable; cannot download.' -ForegroundColor Yellow -Complete
            continue
        }

        try {
            Write-BootstrapModuleStatus -ModuleName $module -Status 'Downloading to cache...' -ForegroundColor Cyan
            $resolvedManifest = Save-ModuleToCache -ModuleName $module -ModuleCacheRoot $moduleCachePath
            if ($resolvedManifest) {
                Import-Module $resolvedManifest -Force -ErrorAction Stop
                Write-BootstrapModuleStatus -ModuleName $module -Status 'Ready (downloaded).' -ForegroundColor Green -Complete
                continue
            }

            Write-BootstrapModuleStatus -ModuleName $module -Status 'Downloaded but no manifest was found in cache.' -ForegroundColor Yellow -Complete
        }
        catch {
            Write-BootstrapModuleStatus -ModuleName $module -Status ("Failed to cache module: {0}" -f $_.Exception.Message) -ForegroundColor Yellow -Complete
        }
    }
    else {
        Write-BootstrapModuleStatus -ModuleName $module -Status 'Already available locally.' -ForegroundColor DarkGray -Complete
    }
}

# --- PREPARE ENVIRONMENT ---
$graphModulesReady = $true
try {
    Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
    Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment -ErrorAction Stop
    Import-Module Microsoft.Graph.Identity.DirectoryManagement -ErrorAction Stop
    Import-Module Microsoft.Graph.Intune -ErrorAction Stop
    Import-Module Microsoft.Graph.Groups -ErrorAction Stop
}
catch {
    $graphModulesReady = $false
    Write-BootstrapMessage -Message ("[Bootstrap] Warning: Could not import one or more Graph modules: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
}

if (-not $graphModulesReady) {
    Write-Host "" 
    throw 'Required Microsoft Graph modules are unavailable. Bootstrap could not complete, so the script is stopping before Connect-MgGraph.'
}

# --- WAM / OPERATOR SELECTION FOR CONNECT-MGGRAPH ---
$wamOperators = @{
    '1' = 'nathan.dawson@hopecc.sa.edu.au'
    '2' = 'faith.carter@hopecc.sa.edu.au'
    '3' = 'will.loughron@hopecc.sa.edu.au'
}

Clear-Host
Write-Host $banner -ForegroundColor Cyan
Write-Host "=== Select WAM Sign-In Account for Connect-MgGraph ===" -ForegroundColor Cyan
Write-Host "1. nathan.dawson@hopecc.sa.edu.au" -ForegroundColor DarkGray
Write-Host "2. faith.carter@hopecc.sa.edu.au" -ForegroundColor DarkGray
Write-Host "3. will.loughron@hopecc.sa.edu.au" -ForegroundColor DarkGray
Write-Host "Press 1, 2, or 3 to continue..." -ForegroundColor DarkGray

$wamChoice = Read-SingleKeyChoice -ValidKeys @('1','2','3')
$wamUser = $wamOperators[$wamChoice]
Set-Clipboard -Value $wamUser
Write-Host "Selected account for Connect-MgGraph: $wamUser" -ForegroundColor Green

if (Get-Command Select-MgProfile -ErrorAction SilentlyContinue) {
    try {
        $betaProfiles = @(Get-Command Select-MgProfile -ErrorAction SilentlyContinue)
        if ($betaProfiles.Count -gt 0) {
            Select-MgProfile -Name 'beta' -ErrorAction Stop | Out-Null
            Write-Host "[Progress] Using Microsoft Graph beta profile for Autopilot checks." -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Host "Warning: Could not select Microsoft Graph beta profile. Continuing with the default profile." -ForegroundColor Yellow
    }
}

Write-Host "Sign into your Microsoft Account" -ForegroundColor Cyan
Write-Host "Your email address has been copied to the clipboard" -ForegroundColor Green

# --- CONNECT TO GRAPH ---
Connect-MgGraph -Scopes `
    "Device.ReadWrite.All", `
    "DeviceManagementServiceConfig.ReadWrite.All", `
    "DeviceManagementManagedDevices.ReadWrite.All", `
    "Directory.AccessAsUser.All"


# --- PULL SERIAL FROM BIOS ---
$serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
$deviceName = $env:COMPUTERNAME
Write-Host "Serial number pulled from BIOS: $serial" -ForegroundColor Cyan

# --- GROUP TAG SELECTION MENU ---
do {
    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "=== Select Group Tag ===" -ForegroundColor Cyan
    Write-Host "1. HCC-STU-SEN" -ForegroundColor DarkGray
    Write-Host "2. HCC-STU-MID" -ForegroundColor DarkGray
    $choice = Read-Host "Enter 1 or 2"

    switch ($choice.Trim()) {
        '1' { 
            $groupTag = 'HCC-STU-SEN'
            $valid = $true
        }
        '2' {
            $groupTag = 'HCC-STU-MID'
            $valid = $true
        }
        default {
            Write-Host "Invalid selection. Please try again..." -ForegroundColor Red
            $valid = $false
        }
    }
} until ($valid)

Write-Host "You selected: $groupTag" -ForegroundColor Green

Clear-Host
Write-Host $banner -ForegroundColor Cyan
# --- STEP 1: REMOVE DEVICE FROM AUTOPILOT / INTUNE / ENTRA ---
Write-Host "Searching for and removing device..." -ForegroundColor Cyan

# Remove from Autopilot
$ap = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -Filter ("contains(serialNumber,'{0}')" -f $serial) |
    Where-Object { $_.SerialNumber -eq $serial }

# Capture IDs before deleting anything
$autopilotId = $null
$managedDeviceId = $null
$azureAdDeviceId = $null
$entraObjectId = $null

if ($ap) {
    $autopilotId = $ap.Id
    $managedDeviceId = $ap.ManagedDeviceId
    $azureAdDeviceId = $ap.AzureAdDeviceId

    Write-Host "=== DEVICE REFERENCES ===" -ForegroundColor Cyan
    Write-Host "Device Name      : $deviceName" -ForegroundColor DarkGray
    Write-Host "Serial Number    : $serial" -ForegroundColor DarkGray
    Write-Host "Autopilot ID     : $autopilotId" -ForegroundColor DarkGray
    Write-Host "ManagedDevice ID : $managedDeviceId" -ForegroundColor DarkGray
    Write-Host "AzureAD Device ID: $azureAdDeviceId" -ForegroundColor DarkGray
}

# DELETE AUTOPILOT

if ($autopilotId) {
    try {
        Remove-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity `
        -WindowsAutopilotDeviceIdentityId $autopilotId `
        -Confirm:$false `
        -ErrorAction Stop

        Write-Host "Removed from Autopilot." -ForegroundColor Yellow
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match 'ZtdDeviceDeletionInProgess|deletion in progress|Deletion for the device|BadRequest') {
            Write-Host "✓ Autopilot deletion is already in progress or was recently requested." -ForegroundColor DarkYellow
        }
        else {
            Write-Host "✗ Failed to remove Autopilot: $errorMessage" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "Not found in Autopilot." -ForegroundColor Gray
}

# DELETE INTUNE

if (-not $managedDeviceId) {
    $intuneRemovalQueryFilter = "contains(serialNumber,'{0}')" -f $serial
    $intuneDeviceBySerial = Get-MgDeviceManagementManagedDevice -Filter $intuneRemovalQueryFilter -ErrorAction Stop |
        Where-Object { $_.SerialNumber -eq $serial } |
        Select-Object -First 1

    if ($intuneDeviceBySerial) {
        $managedDeviceId = $intuneDeviceBySerial.Id
        Write-Host "Found Intune device by serial number: $serial" -ForegroundColor Cyan
    }
}

if ($managedDeviceId) {
    try {
        Remove-MgDeviceManagementManagedDevice `
        -ManagedDeviceId $managedDeviceId `
        -Confirm:$false `
        -ErrorAction Stop

        Write-Host "Removed from Intune." -ForegroundColor Yellow
    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match 'ResourceNotFound|NotFound|404|UnknownInConvertApiError|00000000-0000-0000-0000-000000000000') {
            Write-Host "✓ Intune object already removed or not found." -ForegroundColor DarkYellow
        }
        else {
            Write-Host "✗ Intune removal failed: $errorMessage" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "Not found in Intune managed devices." -ForegroundColor Gray
}

# -----------------------------

# DELETE ENTRA

# -----------------------------

if ($azureAdDeviceId) {
    try {
        $entraDevice = Get-MgDevice -Filter ("deviceId eq '{0}'" -f $azureAdDeviceId) -Property Id,DisplayName,DeviceId -ErrorAction Stop |
        Select-Object -First 1

    if ($entraDevice) {
        $entraObjectId = $entraDevice.Id

        Write-Host "Found Entra Device: $($entraDevice.DisplayName)" -ForegroundColor Cyan
        Write-Host "Object ID: $($entraDevice.Id)" -ForegroundColor DarkGray

        Remove-MgDevice `
            -DeviceId $entraDevice.Id `
            -Confirm:$false `
            -ErrorAction Stop

        Write-Host "✓ Removed from Entra" -ForegroundColor Green

    }
    else {

        Write-Host "No Entra device found using DeviceId $azureAdDeviceId" -ForegroundColor Yellow
    }

    }
    catch {
        $errorMessage = $_.Exception.Message
        if ($errorMessage -match 'ResourceNotFound|NotFound|404') {
            Write-Host "✓ Entra object already removed or not found." -ForegroundColor DarkYellow
        }
        else {
            Write-Host "✗ Entra removal failed: $errorMessage" -ForegroundColor Red
        }
    }
}
else {
    Write-Host "No AzureAD Device ID found" -ForegroundColor Yellow
}

# --- STEP 2: WAIT FOR REMOVAL CONFIRMATION ---
Write-Host "Waiting for full device removal..." -ForegroundColor Cyan
$removalStart = Get-Date
$lastRemovalStatusTime = $null
$removalCompletedSuccessfully = $false

$removalHistory = @(Get-WaitHistory -TaskName 'DeviceRemoval')
$removalEstimateSummary = $null
if ($removalHistory.Count -gt 0) {
    $removalEstimateSummary = Get-WaitEstimateSummary -Values $removalHistory
}

if ($null -eq $removalEstimateSummary) {
    $removalEstimateSeconds = 60
    Write-Host "Estimated removal wait: no prior history available; using 60 seconds as an initial guide." -ForegroundColor DarkCyan
}
else {
    $removalEstimateSeconds = [int]$removalEstimateSummary.Median
    $lowerDisplay = Format-EstimatedDuration -Seconds $removalEstimateSummary.LowerBound
    $upperDisplay = Format-EstimatedDuration -Seconds $removalEstimateSummary.UpperBound
    $medianDisplay = Format-EstimatedDuration -Seconds $removalEstimateSummary.Median
    Write-Host ("Estimated removal wait: between {0} and {1} (median {2}) based on {3} successful run{4}." -f $lowerDisplay, $upperDisplay, $medianDisplay, $removalHistory.Count, $(if ($removalHistory.Count -eq 1) { '' } else { 's' })) -ForegroundColor DarkCyan
}

$autopilotStateText = 'gone'
$intuneStateText = 'gone'
$entraStateText = 'gone'

Do {
    Start-Sleep -Seconds 1

    $autopilotQueryFilter = "contains(serialNumber,'{0}')" -f $serial
    $intuneQueryFilter = "contains(serialNumber,'{0}')" -f $serial
    $autopilotQueryResult = @(Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -Filter $autopilotQueryFilter | Where-Object { $_.SerialNumber -eq $serial })
    $intuneQueryResult = @(Get-MgDeviceManagementManagedDevice -Filter $intuneQueryFilter | Where-Object { $_.SerialNumber -eq $serial })

    $autopilotExists = $autopilotQueryResult.Count -gt 0
    $intuneExists = $intuneQueryResult.Count -gt 0
    $entraExists = $false

    $stillExists = $autopilotExists -or $intuneExists -or $entraExists
    $removalElapsedSeconds = [int]((Get-Date) - $removalStart).TotalSeconds
    $hours = [int][Math]::Floor($removalElapsedSeconds / 3600)
    $minutes = [int][Math]::Floor(($removalElapsedSeconds % 3600) / 60)
    $seconds = [int]($removalElapsedSeconds % 60)
    $elapsedDisplay = "{0:D2}.{1:D2}.{2:D2}" -f $hours, $minutes, $seconds

    if (-not $lastRemovalStatusTime -or ((Get-Date) - $lastRemovalStatusTime).TotalSeconds -ge 1) {
        if ($stillExists) {
            $autopilotStateText = if ($autopilotExists) { 'present' } else { 'gone' }
            $autopilotColor = if ($autopilotExists) { 'Red' } else { 'Green' }
            $intuneStateText = if ($intuneExists) { 'present' } else { 'gone' }
            $intuneColor = if ($intuneExists) { 'Red' } else { 'Green' }

            $removalSegments = @(
                [pscustomobject]@{ Text = 'Removal: waiting for device removal | Autopilot='; Color = 'DarkYellow' }
                [pscustomobject]@{ Text = $autopilotStateText; Color = $autopilotColor }
                [pscustomobject]@{ Text = ' Intune='; Color = 'DarkYellow' }
                [pscustomobject]@{ Text = $intuneStateText; Color = $intuneColor }
            )
            Write-TaskTimerLine -StatusMessage 'Removal: waiting for device removal' -Segments $removalSegments -ElapsedSeconds $removalElapsedSeconds -EstimateSeconds $removalEstimateSeconds -ForegroundColor DarkYellow
        }
        else {
            $removalCompletedSuccessfully = $true
            Write-TaskTimerLine -StatusMessage 'Removal: device removal confirmed' -ElapsedSeconds $removalElapsedSeconds -EstimateSeconds $removalEstimateSeconds -ForegroundColor Green
        }

        $lastRemovalStatusTime = Get-Date
    }
} While ($stillExists)

if ($removalCompletedSuccessfully) {
    $removalDurationSeconds = [int][Math]::Round(((Get-Date) - $removalStart).TotalSeconds, 0)
    $removalHistory += $removalDurationSeconds
    Save-WaitHistory -TaskName 'DeviceRemoval' -Durations $removalHistory
}

Complete-StatusLine
# --- STEP 3: ENROLL TO AUTOPILOT WITH GROUP TAG ---
Write-Host "Starting Autopilot enrollment request..." -ForegroundColor Cyan
Write-Host "Importing device to Autopilot with GroupTag '$groupTag'" -ForegroundColor Yellow
$autopilotImportStart = Get-Date
Write-Host "Running Autopilot import command..." -ForegroundColor Green
Add-CurrentDeviceToAutopilot -SerialNumber $serial -GroupTag $groupTag | Out-Null
$autopilotImportDurationSeconds = [int][Math]::Round(((Get-Date) - $autopilotImportStart).TotalSeconds, 0)
$autopilotImportHistory = @(Get-WaitHistory -TaskName 'AutopilotImportRun')
$autopilotImportHistory += $autopilotImportDurationSeconds
Save-WaitHistory -TaskName 'AutopilotImportRun' -Durations $autopilotImportHistory
Write-Host "Monitoring enrollment status..." -ForegroundColor Cyan

# --- STEP 4: WAIT FOR AUTOPILOT ENROLLMENT ---
$status = $null
$enrollmentStepHistories = @{ 
    Registration = @(Get-WaitHistory -TaskName 'Enrollment-Registration')
    NotAssigned = @(Get-WaitHistory -TaskName 'Enrollment-NotAssigned')
    Pending = @(Get-WaitHistory -TaskName 'Enrollment-Pending')
    Assigned = @(Get-WaitHistory -TaskName 'Enrollment-Assigned')
    Other = @(Get-WaitHistory -TaskName 'Enrollment-Other')
}
$enrollmentEstimateSeconds = Get-EnrollmentStepEstimateSeconds -Status $status -StepHistories $enrollmentStepHistories
$enrollmentEstimateDisplay = Get-EnrollmentStepEstimateDisplay -Status $status -StepHistories $enrollmentStepHistories -FallbackSeconds $enrollmentEstimateSeconds
$enrollmentElapsedSeconds = 0
$lastEnrollmentStatus = $null
$lastEnrollmentStatusStartTime = Get-Date
$enrollmentCompleted = $false
$positiveEnrollmentChecks = 0
$requiredPositiveEnrollmentChecks = 2

Write-Host "Monitoring Autopilot enrollment for serial $serial..." -ForegroundColor Cyan


Do {
    Start-Sleep -Seconds 1

    $device = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -Filter ("contains(serialNumber,'{0}')" -f $serial) |
        Where-Object { $_.SerialNumber -eq $serial }

    $status = if ($null -eq $device) { $null } else { $device.DeploymentProfileAssignmentStatus }
    $currentStatusElapsedSeconds = [int]((Get-Date) - $lastEnrollmentStatusStartTime).TotalSeconds

    $statusChanged = $status -ne $lastEnrollmentStatus
    if ($statusChanged) {
        Save-EnrollmentStepDuration -Status $lastEnrollmentStatus -DurationSeconds $currentStatusElapsedSeconds -StepHistories $enrollmentStepHistories

        $lastEnrollmentStatus = $status
        $lastEnrollmentStatusStartTime = Get-Date
        $enrollmentElapsedSeconds = 0
    }
    else {
        $enrollmentElapsedSeconds = $currentStatusElapsedSeconds
    }

    $enrollmentEstimateSeconds = Get-EnrollmentStepEstimateSeconds -Status $status -StepHistories $enrollmentStepHistories
    $enrollmentEstimateDisplay = Get-EnrollmentStepEstimateDisplay -Status $status -StepHistories $enrollmentStepHistories -FallbackSeconds $enrollmentEstimateSeconds

    $isPositiveEnrollmentCheck = $false
    if (Test-IsAssignedEnrollmentStatus -Status $status) {
        $isPositiveEnrollmentCheck = $true
    }

    if ($isPositiveEnrollmentCheck) {
        $positiveEnrollmentChecks += 1
    }
    else {
        $positiveEnrollmentChecks = 0
    }

    $enrollmentCompleted = $positiveEnrollmentChecks -ge $requiredPositiveEnrollmentChecks

    $statusColor = 'DarkYellow'

    switch ($status) {
        $null {
            $statusMessage = 'Waiting for the device to register with Autopilot...'
            $statusColor = 'Blue'
        }
        'notAssigned' {
            $statusMessage = 'Waiting for the profile assignment to be applied...'
            $statusColor = 'Yellow'
        }
        'pending' {
            $statusMessage = 'Assignment is now pending...'
            $statusColor = 'DarkYellow'
        }
        'assignedUnkownSyncState' {
            $statusMessage = 'Assignment completed successfully. Confirming status...'
            $statusColor = 'Green'
        }
        'assignedUnknownSyncState' {
            $statusMessage = 'Assignment completed successfully. Confirming status...'
            $statusColor = 'Green'
        }
        default {
            $statusMessage = "Status: $status"
            $statusColor = 'Magenta'
        }
    }

    Write-TaskTimerLine -StatusMessage ("Enrollment: {0}" -f $statusMessage) -ElapsedSeconds $enrollmentElapsedSeconds -EstimateSeconds $enrollmentEstimateSeconds -EstimateDisplay $enrollmentEstimateDisplay -ForegroundColor $statusColor -NewLine:$statusChanged
} Until ($enrollmentCompleted)

if ($enrollmentCompleted) {
    $enrollmentDurationSeconds = [int][Math]::Round($enrollmentElapsedSeconds, 0)
    if ($enrollmentDurationSeconds -gt 0) {
        Save-EnrollmentStepDuration -Status $status -DurationSeconds $enrollmentDurationSeconds -StepHistories $enrollmentStepHistories
    }
$banner = @"
███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗
██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗
╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║
███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║
╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝
"@

Write-Host $banner -ForegroundColor Green

    Write-Host "Profile assignment completed successfully." -ForegroundColor Green
    Write-Host "Restarting in 5 seconds..." -ForegroundColor Yellow
    for ($i = 5; $i -ge 1; $i--) {
        Write-Host "$i..." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    Restart-Computer -Force
}
elseif ($status -eq $null) {
    Write-Host "Autopilot enrollment did not register the device." -ForegroundColor Red
}
else {
    Write-Host "Autopilot enrollment did not complete. Last reported status: $status" -ForegroundColor Red
}

try {
    Stop-Transcript | Out-Null
}
catch {
}
