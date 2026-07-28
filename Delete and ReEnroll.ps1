# --- INSTALL NUGET ---

Install-PackageProvider -Name NuGet -Force

# --- INSTALL REQUIRED MODULES IF MISSING ---
$requiredModules = @(
    'Microsoft.Graph.Authentication',
    'Microsoft.Graph.DeviceManagement',
    'Microsoft.Graph.Beta.DeviceManagement.Enrollment'
    )

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing module: $module..." -ForegroundColor Cyan
        Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
    }
    Import-Module $module -Force
}

# --- PREPARE ENVIRONMENT ---
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.DeviceManagement -ErrorAction Stop
Import-Module Microsoft.Graph.Beta.DeviceManagement.Enrollment -ErrorAction Stop

# --- CONNECT TO GRAPH ---
Connect-MgGraph -Scopes `
    "Device.ReadWrite.All", `
    "DeviceManagementServiceConfig.ReadWrite.All", `
    "DeviceManagementManagedDevices.ReadWrite.All", `
    "Directory.AccessAsUser.All"


# --- PULL SERIAL FROM BIOS ---
$serial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
Write-Host "`nSerial number pulled from BIOS: $serial" -ForegroundColor Cyan


# --- GROUP TAG SELECTION MENU ---
do {
    Clear-Host
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


# --- STEP 1: REMOVE DEVICE FROM AUTOPILOT / INTUNE / ENTRA ---
Write-Host "`nSearching and removing device..." -ForegroundColor Cyan

# Remove from Autopilot
$ap = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -All | Where-Object { $_.SerialNumber -eq $serial }
if ($ap) {
    Remove-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $ap.Id -Confirm:$false
    Write-Host "Removed from Autopilot." -ForegroundColor Yellow
} else {
    Write-Host "Not found in Autopilot." -ForegroundColor Gray
}

# Remove from Intune
$md = Get-MgDeviceManagementManagedDevice -All | Where-Object { $_.SerialNumber -eq $serial }
if ($md) {
    Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $md.Id -Confirm:$false
    Write-Host "Removed from Intune." -ForegroundColor Yellow
} else {
    Write-Host "Not found in Intune managed devices." -ForegroundColor Gray
}

# --- STEP 2: WAIT FOR REMOVAL CONFIRMATION ---
Write-Host "`nWaiting for full device removal..." -ForegroundColor Cyan

do {
    Start-Sleep -Seconds 30
    $stillExists = (
        (Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -All | Where-Object { $_.SerialNumber -eq $serial }) -or
        (Get-MgDeviceManagementManagedDevice -All | Where-Object { $_.SerialNumber -eq $serial })
    )
    Write-Host "$(Get-Date -Format 'T') - Still waiting for removal..." -ForegroundColor DarkYellow
} while ($stillExists)

Write-Host "Device removal confirmed." -ForegroundColor Green

# --- STEP 3: ENROLL TO AUTOPILOT WITH GROUP TAG ---
Write-Host "`nEnrolling device to Autopilot with GroupTag '$groupTag'" -ForegroundColor Cyan

if (-not (Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
    Install-Script -Name Get-WindowsAutopilotInfo -Force
}

Get-WindowsAutopilotInfo -Online -GroupTag $groupTag

# --- STEP 4: WAIT FOR GROUP TAG + PROFILE ASSIGNMENT ---
$maxAttempts = 60  # 30 minutes max (30 sec intervals)
$attempt = 0

Write-Host "Waiting for Deployment Profile to be assigned for serial $serial..." -ForegroundColor Yellow

do {
    Start-Sleep -Seconds 15


    $attempt++

    $device = Get-MgBetaDeviceManagementWindowsAutopilotDeviceIdentity -All |
        Where-Object { $_.SerialNumber -eq $serial }

    if ($null -eq $device) {
        $status = $null
    } else {
        $status = $device.DeploymentProfileAssignmentStatus
    }

    switch ($status) {
      
        $null { Write-Host "Status: waiting for device to appear" -ForegroundColor Gray}

        "notAssigned" { Write-Host "Status: waiting for device to be assigned" -ForegroundColor DarkYellow }

        "pending" { Write-Host "Status: pending assignment" -ForegroundColor Yellow }
        
        "assignedUnkownSyncState" { Write-Host "Status: assigned" -ForegroundColor Green }
    }

} until (
    $status -eq "assignedUnkownSyncState" -or
    $attempt -ge $maxAttempts
)

if ($status -eq "assignedUnkownSyncState") {
    Write-Host "Profile assignment complete." -ForegroundColor Green
    Write-Host "`nRestarting in 5 seconds..." -ForegroundColor Yellow
for ($i = 5; $i -ge 1; $i--) {
    Write-Host "$i..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

Restart-Computer -Force

} elseif ($status -eq $null) {
    Write-Host "Device never appeared in Autopilot." -ForegroundColor Red
} else {
    Write-Host "Timed out waiting for assignment. Last status: $status" -ForegroundColor Red
}
