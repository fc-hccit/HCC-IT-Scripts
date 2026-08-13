#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ITManagementSubnet = ""

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RuleName = 'College IT - SMB Admin'
$RuleDescription = 'Created by Deploy-RemoteFileAccess.ps1 for restricted administrative SMB access over TCP 445.'
$SolutionRoot = Join-Path -Path $env:ProgramData -ChildPath 'CollegeIT\RemoteFileAccess'
$LogDirectory = Join-Path -Path $SolutionRoot -ChildPath 'Logs'
$StateDirectory = Join-Path -Path $SolutionRoot -ChildPath 'State'
$StateFile = Join-Path -Path $StateDirectory -ChildPath 'RemoteFileAccess-State.json'
$LogFile = Join-Path -Path $LogDirectory -ChildPath ('Deploy-RemoteFileAccess-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

function Initialize-Directories {
    foreach ($path in @($SolutionRoot, $LogDirectory, $StateDirectory)) {
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
}

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $entry = '{0} [{1}] {2}' -f $timestamp, $Level, $Message
    Write-Host $entry
    Add-Content -Path $LogFile -Value $entry
}

function Get-LanmanServerInfo {
    $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='LanmanServer'"

    if (-not $service) {
        throw 'LanmanServer service was not found.'
    }

    [pscustomobject]@{
        Name      = $service.Name
        State     = $service.State
        StartMode = $service.StartMode
    }
}

function Get-AutoShareSetting {
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'

    if (-not (Test-Path -Path $path)) {
        return $null
    }

    try {
        return (Get-ItemProperty -Path $path -Name AutoShareWks -ErrorAction Stop).AutoShareWks
    }
    catch {
        return $null
    }
}

function Test-AdminShareExists {
    try {
        $null = Get-SmbShare -Name 'C$' -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

function Get-RemoteAddressCanonicalString {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$RemoteAddress
    )

    $normalized = $RemoteAddress.Split(',') |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ } |
        Sort-Object -Unique

    return ($normalized -join ',')
}

function Get-ConfiguredRemoteAddress {
    if ([string]::IsNullOrWhiteSpace($ITManagementSubnet)) {
        return 'Any'
    }

    return Get-RemoteAddressCanonicalString -RemoteAddress $ITManagementSubnet
}

function Get-FirewallRuleState {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DisplayName
    )

    $rule = Get-NetFirewallRule -DisplayName $DisplayName -ErrorAction SilentlyContinue | Select-Object -First 1

    if (-not $rule) {
        return $null
    }

    $portFilter = $rule | Get-NetFirewallPortFilter
    $addressFilter = $rule | Get-NetFirewallAddressFilter

    [pscustomobject]@{
        Rule             = $rule
        LocalPort        = $portFilter.LocalPort
        Protocol         = $portFilter.Protocol
        RemoteAddress    = Get-RemoteAddressCanonicalString -RemoteAddress ($addressFilter.RemoteAddress -join ',')
        Description      = $rule.Description
        Enabled          = $rule.Enabled
        Direction        = $rule.Direction
        Action           = $rule.Action
        Profile          = $rule.Profile
    }
}

function Get-FirewallPolicyBlockers {
    $profiles = Get-NetFirewallProfile -PolicyStore ActiveStore
    $blockers = @()

    foreach ($profile in $profiles) {
        if (-not $profile.Enabled) {
            continue
        }

        if (-not $profile.AllowLocalFirewallRules) {
            $blockers += "Firewall profile '$($profile.Name)' does not allow local firewall rules. An Intune or Defender Firewall policy may override the local TCP 445 rule."
        }

        if (-not $profile.AllowInboundRules) {
            $blockers += "Firewall profile '$($profile.Name)' is configured to disallow inbound rules. The local TCP 445 rule may not be effective."
        }
    }

    return $blockers
}

function Get-PreflightBlockers {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$ShareExists,

        [AllowNull()]
        [int]$AutoShareWks,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [psobject]$ExistingRuleState
    )

    $preflightBlockers = New-Object System.Collections.Generic.List[string]

    if (-not $ShareExists -and $AutoShareWks -eq 0) {
        $preflightBlockers.Add('Administrative shares are explicitly disabled by AutoShareWks=0. This script will not override that policy.')
    }

    if ($ExistingRuleState -and $ExistingRuleState.Description -and $ExistingRuleState.Description -ne $RuleDescription) {
        $preflightBlockers.Add("A firewall rule named '$RuleName' already exists but does not match this solution. Manual review is required before this script can manage that rule.")
    }

    foreach ($blocker in (Get-FirewallPolicyBlockers)) {
        $preflightBlockers.Add($blocker)
    }

    return $preflightBlockers
}

function Get-LocalAccountTokenFilterPolicyValue {
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'

    try {
        return (Get-ItemProperty -Path $path -Name LocalAccountTokenFilterPolicy -ErrorAction Stop).LocalAccountTokenFilterPolicy
    }
    catch {
        return $null
    }
}

function Get-WinRMState {
    $service = Get-Service -Name WinRM -ErrorAction SilentlyContinue
    $listenerCount = 0

    try {
        $listenerCount = (Get-ChildItem -Path WSMan:\LocalHost\Listener -ErrorAction Stop | Measure-Object).Count
    }
    catch {
        $listenerCount = 0
    }

    [pscustomobject]@{
        ServiceStatus = if ($service) { $service.Status } else { 'NotInstalled' }
        StartType     = if ($service) { $service.StartType } else { 'Unknown' }
        ListenerCount = $listenerCount
    }
}

function Get-Tcp445Listening {
    try {
        return [bool](Get-NetTCPConnection -LocalPort 445 -State Listen -ErrorAction Stop)
    }
    catch {
        return $false
    }
}

function Import-DeploymentState {
    if (Test-Path -Path $StateFile) {
        return Get-Content -Path $StateFile -Raw | ConvertFrom-Json
    }

    return $null
}

function Export-DeploymentState {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$State
    )

    $State | ConvertTo-Json -Depth 5 | Set-Content -Path $StateFile -Encoding UTF8
}

Initialize-Directories
Write-Log -Message 'Starting Deploy-RemoteFileAccess.ps1'

$blockers = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$configuredRemoteAddress = Get-ConfiguredRemoteAddress

$lanmanInfo = Get-LanmanServerInfo
$state = Import-DeploymentState

if (-not $state) {
    $state = [pscustomobject]@{
        LanmanServerOriginalStartMode = $lanmanInfo.StartMode
        LanmanServerOriginalState = $lanmanInfo.State
        LanmanServerStartupChangedByDeploy = $false
        LanmanServerStartedByDeploy = $false
        ManagedFirewallRule = $false
        RuleName = $RuleName
        LastUpdatedUtc = (Get-Date).ToUniversalTime().ToString('o')
    }
}

Write-Log -Message ("LanmanServer current state: {0}, start mode: {1}" -f $lanmanInfo.State, $lanmanInfo.StartMode)
Write-Log -Message ("TCP 445 listening before changes: {0}" -f (Get-Tcp445Listening))

$autoShareWks = Get-AutoShareSetting
if ($null -ne $autoShareWks) {
    Write-Log -Message ("AutoShareWks is set to {0}" -f $autoShareWks)
}
else {
    Write-Log -Message 'AutoShareWks is not explicitly set.'
}

$shareExistsBefore = Test-AdminShareExists
Write-Log -Message ("C$ exists before changes: {0}" -f $shareExistsBefore)

$existingRuleState = Get-FirewallRuleState -DisplayName $RuleName
$expectedRemoteAddress = $configuredRemoteAddress

foreach ($blocker in (Get-PreflightBlockers -ShareExists $shareExistsBefore -AutoShareWks $autoShareWks -ExistingRuleState $existingRuleState)) {
    $blockers.Add($blocker)
}

if ($blockers.Count -gt 0) {
    foreach ($blocker in $blockers) {
        Write-Log -Message $blocker -Level 'ERROR'
    }

    Write-Log -Message 'No changes were applied because preflight checks found blockers requiring manual intervention.' -Level 'ERROR'
    exit 1
}

if ($lanmanInfo.StartMode -eq 'Disabled') {
    Write-Log -Message 'LanmanServer is disabled. Setting startup type to Automatic because SMB hosting cannot function while the service is disabled.' -Level 'WARN'
    Set-Service -Name LanmanServer -StartupType Automatic
    $state.LanmanServerStartupChangedByDeploy = $true
}

if ($lanmanInfo.State -ne 'Running') {
    Write-Log -Message 'Starting LanmanServer because administrative shares require the Server service.'
    Start-Service -Name LanmanServer
    $state.LanmanServerStartedByDeploy = $true
}

$shareExistsAfterService = Test-AdminShareExists
Write-Log -Message ("C$ exists after service checks: {0}" -f $shareExistsAfterService)

if (-not $shareExistsAfterService -and $autoShareWks -ne 0) {
    $blockers.Add('C$ is still unavailable after ensuring LanmanServer is running. Manual investigation is required.')
}

if ($blockers.Count -eq 0) {
    if (-not $existingRuleState) {
        Write-Log -Message ("Creating firewall rule '$RuleName' for TCP 445 with RemoteAddress '{0}'." -f $configuredRemoteAddress)
        New-NetFirewallRule -DisplayName $RuleName -Description $RuleDescription -Direction Inbound -Action Allow -Enabled True -Profile Any -Protocol TCP -LocalPort 445 -RemoteAddress $configuredRemoteAddress | Out-Null
    }
    else {
        Write-Log -Message ("Updating firewall rule '$RuleName' to match the required TCP 445 and RemoteAddress settings.")
        $existingRuleState.Rule |
            Set-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -Profile Any -Description $RuleDescription | Out-Null
        $existingRuleState.Rule |
            Get-NetFirewallPortFilter |
            Set-NetFirewallPortFilter -Protocol TCP -LocalPort 445 | Out-Null
        $existingRuleState.Rule |
            Get-NetFirewallAddressFilter |
            Set-NetFirewallAddressFilter -RemoteAddress $configuredRemoteAddress | Out-Null
    }

    $state.ManagedFirewallRule = $true
}

$latfpValue = Get-LocalAccountTokenFilterPolicyValue
if ($null -eq $latfpValue) {
    $warnings.Add('LocalAccountTokenFilterPolicy is not set. This is expected on many systems, but non-RID 500 local admin accounts may still be subject to remote UAC token filtering.')
}
elseif ($latfpValue -eq 0) {
    $warnings.Add('LocalAccountTokenFilterPolicy is explicitly set to 0. Non-RID 500 local admin accounts may be filtered for remote admin share access.')
}
else {
    Write-Log -Message ("LocalAccountTokenFilterPolicy is set to {0}." -f $latfpValue) -Level 'WARN'
}

$networkProfiles = Get-NetConnectionProfile -ErrorAction SilentlyContinue
foreach ($profile in $networkProfiles) {
    Write-Log -Message ("Active network profile '{0}' is {1}." -f $profile.Name, $profile.NetworkCategory)
}

$winRmState = Get-WinRMState
Write-Log -Message ("WinRM assessment only: status={0}, start type={1}, listeners={2}. No WinRM changes were made." -f $winRmState.ServiceStatus, $winRmState.StartType, $winRmState.ListenerCount)

$finalRuleState = Get-FirewallRuleState -DisplayName $RuleName
if ($finalRuleState) {
    Write-Log -Message ("Firewall rule state: enabled={0}, protocol={1}, localport={2}, remoteaddress={3}." -f $finalRuleState.Enabled, $finalRuleState.Protocol, $finalRuleState.LocalPort, $finalRuleState.RemoteAddress)

    if ($finalRuleState.RemoteAddress -ne $expectedRemoteAddress) {
        $blockers.Add("Firewall rule '$RuleName' does not match the expected RemoteAddress value '$expectedRemoteAddress'.")
    }
}

Write-Log -Message ("TCP 445 listening after changes: {0}" -f (Get-Tcp445Listening))

$state.LastUpdatedUtc = (Get-Date).ToUniversalTime().ToString('o')
Export-DeploymentState -State $state

foreach ($warning in $warnings) {
    Write-Log -Message $warning -Level 'WARN'
}

if ($blockers.Count -gt 0) {
    foreach ($blocker in $blockers) {
        Write-Log -Message $blocker -Level 'ERROR'
    }

    Write-Log -Message 'Deployment completed with blockers requiring manual intervention.' -Level 'ERROR'
    exit 1
}

Write-Log -Message 'Deployment completed successfully.'
exit 0