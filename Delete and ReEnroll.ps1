$logFile = Join-Path $PSScriptRoot ("Delete-ReEnroll-{0}.log" -f (Get-Date -Format "yyyyMMdd-HHmmss"))

try {
    Start-Transcript -Path $logFile -Append -ErrorAction Stop | Out-Null
    Write-Host "Logging to file: $logFile" -ForegroundColor DarkGray
}
catch {
    Write-Host "Warning: Could not start transcript logging. $($_.Exception.Message)" -ForegroundColor Yellow
}

Clear-Host

function Write-BootstrapMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$ForegroundColor = 'Cyan'
    )

    Write-Host ("`r{0}" -f $Message) -NoNewline -ForegroundColor $ForegroundColor
}

$banner = @"

██████╗ ███████╗██╗         ██████╗███╗   ███╗██████╗
██╔══██╗██╔════╝██║        ██╔════╝████╗ ████║██╔══██╗
██║  ██║█████╗  ██║        ██║     ██╔████╔██║██║  ██║
██║  ██║██╔══╝  ██║        ██║     ██║╚██╔╝██║██║  ██║
██████╔╝███████╗███████╗   ╚██████╗██║ ╚═╝ ██║██████╔╝
╚═════╝ ╚══════╝╚══════╝    ╚═════╝╚═╝     ╚═╝╚═════╝

Delete & Re-Enroll Tool v2.0
"@

Write-Host $banner -ForegroundColor Cyan

Write-BootstrapMessage -Message "[Bootstrap] Initializing PowerShell package sources..." -ForegroundColor Cyan
try {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    Write-BootstrapMessage -Message "[Bootstrap] PSGallery repository trust set to Trusted." -ForegroundColor DarkGray
}
catch {
    Write-BootstrapMessage -Message "[Bootstrap] Warning: Could not set PSGallery trust policy: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

$moduleCachePath = Join-Path $PSScriptRoot 'Modules'
New-Item -ItemType Directory -Path $moduleCachePath -Force | Out-Null

Write-BootstrapMessage -Message "[Bootstrap] Checking NuGet provider availability..." -ForegroundColor Cyan
try {
    $nugetCachePath = Join-Path $moduleCachePath 'NuGetProvider'
    $nugetStateFile = Join-Path $nugetCachePath 'provider.txt'

    if (Test-Path $nugetStateFile) {
        Write-BootstrapMessage -Message "[Bootstrap] NuGet provider cache found; reusing cached state." -ForegroundColor DarkGray
    }
    else {
        Write-BootstrapMessage -Message "[Bootstrap] NuGet provider not cached yet; checking installed providers..." -ForegroundColor DarkGray
        $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue

        if ($nugetProvider) {
            New-Item -ItemType Directory -Path $nugetCachePath -Force | Out-Null
            Set-Content -Path $nugetStateFile -Value $nugetProvider.Name -Encoding UTF8
            Write-BootstrapMessage -Message "[Bootstrap] NuGet provider is available and cached." -ForegroundColor DarkGray
        }
        else {
            Write-BootstrapMessage -Message "[Bootstrap] NuGet provider is not installed. The bootstrap will use direct PSGallery package downloads instead of PackageManagement installs." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-BootstrapMessage -Message "[Bootstrap] Warning: Could not inspect NuGet provider: $($_.Exception.Message)" -ForegroundColor Yellow
}
Write-Host ""

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

# --- LOAD REQUIRED MODULES ---
# Make cached modules discoverable by name for scripts that call Import-Module <Name>.
if (-not (($env:PSModulePath -split ';') -contains $moduleCachePath)) {
    $env:PSModulePath = "$moduleCachePath;$env:PSModulePath"
}

$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.DeviceManagement',
    'Microsoft.Graph.DeviceManagement.Enrollment',
    'Microsoft.Graph.Identity.DirectoryManagement',
    'Microsoft.Graph.Intune',
    'Microsoft.Graph.Groups',
    'WindowsAutoPilotIntune'
    )

Write-Host "[Bootstrap] Preparing module preload for required modules..." -ForegroundColor Cyan
foreach ($module in $requiredModules) {
    Write-Host ("[Bootstrap] Checking module: {0}" -f $module) -ForegroundColor DarkCyan
    $resolvedManifest = Resolve-ModuleManifestPath -ModuleName $module -ModuleCacheRoot $moduleCachePath

    if ($resolvedManifest) {
        try {
            Write-Host ("[Bootstrap] Importing module from existing location: {0}" -f $module) -ForegroundColor Cyan
            Import-Module $resolvedManifest -Force -ErrorAction Stop
            Write-Host ("[Bootstrap] Module ready from existing location: {0}" -f $module) -ForegroundColor Green
            continue
        }
        catch {
            Write-Host ("[Bootstrap] Module '{0}' is present but could not be imported. Attempting to acquire it..." -f $module) -ForegroundColor Yellow
        }
    }

    Write-Host ("[Bootstrap] No local manifest found; acquiring module from PSGallery: {0}" -f $module) -ForegroundColor Cyan
    $isOptionalModule = $module -eq 'WindowsAutoPilotIntune' -or $module -eq 'WindowsAutopilotIntune'

    try {
        Write-Host ("[Bootstrap] Using direct PSGallery package download for {0}" -f $module) -ForegroundColor Yellow
        $packageVersion = $null
        $packageName = $module
        if ($module -eq 'WindowsAutoPilotIntune' -or $module -eq 'WindowsAutopilotIntune') {
            $packageVersion = '5.7'
            $packageName = 'WindowsAutoPilotIntune'
        }
        else {
            $moduleInfo = Find-Module -Name $module -Repository PSGallery -ErrorAction Stop
            if ($moduleInfo -and $moduleInfo.Version) {
                $packageVersion = [string]$moduleInfo.Version
            }
        }

        if (-not $packageVersion) {
            throw "Unable to resolve PSGallery version for module '$module'."
        }

        $packageUrl = "https://www.powershellgallery.com/api/v2/package/$packageName/$packageVersion"
        $packageFile = Join-Path $moduleCachePath ("{0}.{1}.nupkg" -f $packageName, $packageVersion)
        $zipFile = Join-Path $moduleCachePath ("{0}.{1}.zip" -f $packageName, $packageVersion)
        Invoke-WebRequest -Uri $packageUrl -OutFile $packageFile -UseBasicParsing -ErrorAction Stop

        if (Test-Path $zipFile) {
            Remove-Item -Path $zipFile -Force -ErrorAction SilentlyContinue
        }

        Copy-Item -Path $packageFile -Destination $zipFile -Force

        $packageRoot = Join-Path $moduleCachePath $packageName
        New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null
        Expand-Archive -Path $zipFile -DestinationPath $packageRoot -Force -ErrorAction Stop

        $extractedManifest = Get-ChildItem -Path $packageRoot -Filter "$packageName.psd1" -Recurse -File -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if (-not $extractedManifest) {
            throw "Downloaded package did not contain a manifest for '$packageName'."
        }

        Write-Host ("[Bootstrap] Direct package download succeeded for {0}" -f $module) -ForegroundColor DarkGray
    }
    catch {
        if ($isOptionalModule) {
            Write-Host ("[Bootstrap] Optional module download failed for {0}; continuing without it. {1}" -f $module, $_.Exception.Message) -ForegroundColor Yellow
            continue
        }

        Write-Host ("Download failed for {0}: {1}" -f $module, $_.Exception.Message) -ForegroundColor Yellow
        throw
    }

    $resolvedManifest = Resolve-ModuleManifestPath -ModuleName $module -ModuleCacheRoot $moduleCachePath

    if ($resolvedManifest) {
        Write-Host ("[Bootstrap] Module acquired and loaded successfully: {0}" -f $module) -ForegroundColor Green
        Import-Module $resolvedManifest -Force -ErrorAction Stop
        continue
    }

    if ($isOptionalModule) {
        Write-Host ("[Bootstrap] Optional module was not available after download attempt: {0}" -f $module) -ForegroundColor Yellow
        continue
    }

    throw "Unable to locate or import module '$module' after download."
}

# --- PREPARE ENVIRONMENT ---
# Required modules are imported in the preload loop above.

# --- WAM / OPERATOR SELECTION FOR CONNECT-MGGRAPH ---
$wamOperators = @{
    '1' = 'nathan.dawson@hopecc.sa.edu.au'
    '2' = 'faith.carter@hopecc.sa.edu.au'
    '3' = 'will.loughron@hopecc.sa.edu.au'
}

Clear-Host
Write-Host $banner -ForegroundColor Cyan
Write-Host "`n=== Select WAM Sign-In Account for Connect-MgGraph ===" -ForegroundColor Cyan
Write-Host "1. nathan.dawson@hopecc.sa.edu.au"
Write-Host "2. faith.carter@hopecc.sa.edu.au"
Write-Host "3. will.loughron@hopecc.sa.edu.au"
Write-Host "Press 1, 2, or 3 to continue..." -ForegroundColor DarkGray

$wamChoice = Read-SingleKeyChoice -ValidKeys @('1','2','3')
$wamUser = $wamOperators[$wamChoice]
Set-Clipboard -Value $wamUser
Write-Host "Selected account for Connect-MgGraph: $wamUser" -ForegroundColor Green

# --- CONNECT TO GRAPH ---
Connect-MgGraph -Scopes `
    "Device.ReadWrite.All", `
    "DeviceManagementServiceConfig.ReadWrite.All", `
    "DeviceManagementManagedDevices.ReadWrite.All", `
    "Directory.AccessAsUser.All"


# --- PULL SERIAL FROM BIOS ---
$serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
$deviceName = $env:COMPUTERNAME
Write-Host "`nSerial number pulled from BIOS: $serial" -ForegroundColor Cyan

# --- GROUP TAG SELECTION MENU ---
do {
    Clear-Host
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "`n=== Select Group Tag ===" -ForegroundColor Cyan
    Write-Host "1. HCC-STU-SEN"
    Write-Host "2. HCC-STU-MID"
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
            Start-Sleep -Seconds 2
        }
    }
} until ($valid)

Write-Host "You selected: $groupTag" -ForegroundColor Green

Clear-Host
Write-Host $banner -ForegroundColor Cyan
# --- STEP 1: REMOVE DEVICE FROM AUTOPILOT / INTUNE / ENTRA ---

Write-Host "`nSearching for device..." -ForegroundColor Cyan

# Find Autopilot device

$ap = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All |
Where-Object { $_.SerialNumber -eq $serial }

# Capture IDs BEFORE deleting anything

$autopilotId = $null
$managedDeviceId = $null
$azureAdDeviceId = $null
$entraObjectId = $null

if ($ap) {


$autopilotId = $ap.Id
$managedDeviceId = $ap.ManagedDeviceId
$azureAdDeviceId = $ap.AzureAdDeviceId

Write-Host ""
Write-Host "=== DEVICE REFERENCES ===" -ForegroundColor Cyan
Write-Host "Device Name      : $deviceName" -ForegroundColor DarkGray
Write-Host "Serial Number    : $serial" -ForegroundColor DarkGray
Write-Host "Autopilot ID     : $autopilotId" -ForegroundColor DarkGray
Write-Host "ManagedDevice ID : $managedDeviceId" -ForegroundColor DarkGray
Write-Host "AzureAD Device ID: $azureAdDeviceId" -ForegroundColor DarkGray
Write-Host ""


}

# -----------------------------

# DELETE AUTOPILOT

# -----------------------------

if ($autopilotId) {


try {


    Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity `
        -WindowsAutopilotDeviceIdentityId $autopilotId `
        -Confirm:$false `
        -ErrorAction Stop 2>$null

    Write-Host "Removal initiated for Autopilot" -ForegroundColor Green


}
catch {


    $message = $_.Exception.Message
    if ($message -match 'ZtdDeviceDeletionInProgess|Deletion.*in progress') {
        Write-Host "Autopilot deletion is already in progress. The script will continue waiting for completion." -ForegroundColor Yellow
    }
    else {
        Write-Host "✗ Failed to remove Autopilot: $message" -ForegroundColor Red
    }


}


}
else {


    Write-Host "No existing Autopilot record found for serial $serial" -ForegroundColor DarkYellow


}

# -----------------------------

# DELETE INTUNE

# -----------------------------

if ($managedDeviceId) {


try {

    Remove-MgDeviceManagementManagedDevice `
        -ManagedDeviceId $managedDeviceId `
        -Confirm:$false `
        -ErrorAction Stop 2>$null

    Write-Host "✓ Removed from Intune" -ForegroundColor Green

}
catch {

    $message = $_.Exception.Message
    if ($message -match 'ResourceNotFound|NotFound|does not exist') {
        Write-Host "Managed device was already absent; continuing." -ForegroundColor DarkGray
    }
    else {
        Write-Host "✗ Intune removal failed: $message" -ForegroundColor Yellow
    }
}


}
else {


Write-Host "No ManagedDeviceId found" -ForegroundColor Gray


}

# -----------------------------

# DELETE ENTRA

# -----------------------------

if ($azureAdDeviceId) {


try {

    $entraDevice = Get-MgDevice -All |
        Where-Object {
            $_.DeviceId -eq $azureAdDeviceId
        } |
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

    Write-Host "✗ Entra removal failed: $($_.Exception.Message)" -ForegroundColor Red
}


}
else {


Write-Host "No AzureAD Device ID found" -ForegroundColor Yellow


}

# --- STEP 2: WAIT FOR REMOVAL CONFIRMATION ---
Write-Host "`nWaiting for full device removal..." -ForegroundColor Cyan
$removalStart = Get-Date
$removalElapsedSeconds = 0
$lastStatusTime = $null

while ($true) {
    $autopilotExists = $false
    if ($autopilotId) {
        try {
            $null = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $autopilotId -ErrorAction Stop 2>$null
            $autopilotExists = $true
        }
        catch {
            $autopilotExists = $false
        }
    }

    $intuneExists = $false
    if ($managedDeviceId) {
        try {
            $null = Get-MgDeviceManagementManagedDevice -ManagedDeviceId $managedDeviceId -ErrorAction Stop 2>$null
            $intuneExists = $true
        }
        catch {
            $intuneExists = $false
        }
    }

    $entraExists = $false
    if ($entraObjectId) {
        try {
            $null = Get-MgDevice -DeviceId $entraObjectId -ErrorAction Stop 2>$null
            $entraExists = $true
        }
        catch {
            $entraExists = $false
        }
    }

    $stillExists = $autopilotExists -or $intuneExists -or $entraExists
    $removalElapsedSeconds = [int]((Get-Date) - $removalStart).TotalSeconds

    if (-not $lastStatusTime -or ((Get-Date) - $lastStatusTime).TotalSeconds -ge 1) {
        $statusText = "Elapsed: $([string]::Format('{0:D2}.{1:D2}.{2:D2}', [int][Math]::Floor($removalElapsedSeconds / 3600), [int][Math]::Floor(($removalElapsedSeconds % 3600) / 60), [int]($removalElapsedSeconds % 60))) | Waiting for removal"
        Write-Host "`r$statusText" -NoNewline -ForegroundColor DarkYellow
        $lastStatusTime = Get-Date
    }

    if (-not $stillExists) {
        break
    }

    Start-Sleep -Seconds 1
}

Write-Host "Device removal confirmed." -ForegroundColor Green
# --- STEP 3: ENROLL TO AUTOPILOT WITH GROUP TAG ---
Write-Host "`nEnrolling device to Autopilot with GroupTag '$groupTag'" -ForegroundColor Cyan

$scriptCachePath = Join-Path $PSScriptRoot 'Scripts'
New-Item -ItemType Directory -Path $scriptCachePath -Force | Out-Null

if (-not (Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    $cachedAutopilotScript = @(Get-ChildItem -Path $scriptCachePath -Filter 'Get-WindowsAutopilotInfo.ps1' -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1)

    if ($cachedAutopilotScript.Count -eq 0) {
        Write-Host "Downloading Autopilot script to cache: Get-WindowsAutopilotInfo" -ForegroundColor Cyan
        Save-Script -Name Get-WindowsAutopilotInfo -Path $scriptCachePath -Force -ErrorAction Stop

        $cachedAutopilotScript = @(Get-ChildItem -Path $scriptCachePath -Filter 'Get-WindowsAutopilotInfo.ps1' -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1)
    }

    if ($cachedAutopilotScript.Count -gt 0) {
        Set-Alias -Name Get-WindowsAutopilotInfo -Value $cachedAutopilotScript[0].FullName -Scope Script
    }
}
Clear-Host
Write-Host $banner -ForegroundColor Cyan
Get-WindowsAutopilotInfo -Online -GroupTag $groupTag

Clear-Host
Write-Host $banner -ForegroundColor Cyan

# --- STEP 4: WAIT FOR AUTOPILOT ENROLLMENT ---
$status = "missing"
$enrollmentState = "missing"
$resolvedAutopilotId = ""
$enrollmentStart = Get-Date
$enrollmentElapsedSeconds = 0
$lastEnrollmentStatusTime = $null

Write-Host "Waiting for Autopilot enrollment state 'enrolled' for serial $serial..." -ForegroundColor Cyan

while ($true) {
    Start-Sleep -Seconds 1

    if ($resolvedAutopilotId) {
        $deviceById = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $resolvedAutopilotId -ErrorAction SilentlyContinue
        if (-not $deviceById) {
            $resolvedAutopilotId = ""
        }
    }

    if (-not $resolvedAutopilotId) {
        $device = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -All |
            Where-Object { $_.SerialNumber -eq $serial } |
            Select-Object -First 1
        if ($device) {
            $resolvedAutopilotId = $device.Id
            $deviceById = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $resolvedAutopilotId -ErrorAction SilentlyContinue
        }
        else {
            $deviceById = $null
        }
    }

    if ($deviceById) {
        $status = [string]$deviceById.DeploymentProfileAssignmentStatus
        $enrollmentState = [string]$deviceById.EnrollmentState
    }
    else {
        $status = "missing"
        $enrollmentState = "missing"
    }

    $enrollmentElapsedSeconds = [int]((Get-Date) - $enrollmentStart).TotalSeconds

    if (-not $lastEnrollmentStatusTime -or ((Get-Date) - $lastEnrollmentStatusTime).TotalSeconds -ge 1) {
        $statusText = "Elapsed: $([string]::Format('{0:D2}.{1:D2}.{2:D2}', [int][Math]::Floor($enrollmentElapsedSeconds / 3600), [int][Math]::Floor(($enrollmentElapsedSeconds % 3600) / 60), [int]($enrollmentElapsedSeconds % 60))) | Waiting for enrollment"
        Write-Host "`r$statusText" -NoNewline -ForegroundColor DarkYellow
        $lastEnrollmentStatusTime = Get-Date
    }

    if ($enrollmentState -eq "enrolled") {
        break
    }
}

if ($enrollmentState -eq "enrolled") {
Clear-Host

Write-Host @"

███████╗██╗   ██╗ ██████╗ ██████╗███████╗███████╗███████╗
██╔════╝██║   ██║██╔════╝██╔════╝██╔════╝██╔════╝██╔════╝
███████╗██║   ██║██║     ██║     █████╗  ███████╗███████╗
╚════██║██║   ██║██║     ██║     ██╔══╝  ╚════██║╚════██║
███████║╚██████╔╝╚██████╗╚██████╗███████╗███████║███████║
╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝╚══════╝╚══════╝╚══════╝

"@ -ForegroundColor Green

    Write-Host "Autopilot enrollment confirmed (EnrollmentState=enrolled)." -ForegroundColor Green
    if ($resolvedAutopilotId) {
        Write-Host "Autopilot ID: $resolvedAutopilotId" -ForegroundColor DarkGray
    }
    Write-Host "`nRestarting in 5 seconds..." -ForegroundColor Yellow
for ($i = 5; $i -ge 1; $i--) {
    Write-Host "$i..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

try {
    Stop-Transcript | Out-Null
}
catch {
}

Restart-Computer -Force

} elseif ($enrollmentState -eq "missing") {
    Write-Host "Device never appeared in Autopilot." -ForegroundColor Red
} else {
    Write-Host "Enrollment monitoring ended with state: $enrollmentState. Assignment: $status" -ForegroundColor Yellow
}

try {
    Stop-Transcript | Out-Null
}
catch {
}
