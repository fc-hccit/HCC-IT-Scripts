[CmdletBinding()]
param()

$ITManagementSubnet = ""

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RuleName = 'College IT - SMB Admin'
$RuleDescription = 'Created by Deploy-RemoteFileAccess.ps1 for restricted administrative SMB access over TCP 445.'

function Write-DetectionMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    Write-Output ('[{0}] {1}' -f $Level, $Message)
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

function Test-AdminShareExists {
    try {
        $null = Get-SmbShare -Name 'C$' -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
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
        Rule          = $rule
        LocalPort     = $portFilter.LocalPort
        Protocol      = $portFilter.Protocol
        RemoteAddress = Get-RemoteAddressCanonicalString -RemoteAddress ($addressFilter.RemoteAddress -join ',')
        Description   = $rule.Description
        Enabled       = $rule.Enabled
        Direction     = $rule.Direction
        Action        = $rule.Action
    }
}

function Get-Smb1Enabled {
    try {
        return [bool](Get-SmbServerConfiguration | Select-Object -ExpandProperty EnableSMB1Protocol)
    }
    catch {
        try {
            $feature = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction Stop
            return $feature.State -eq 'Enabled'
        }
        catch {
            return $false
        }
    }
}

function Get-FirewallPolicyBlockers {
    $profiles = Get-NetFirewallProfile -PolicyStore ActiveStore
    $issues = @()

    foreach ($profile in $profiles) {
        if (-not $profile.Enabled) {
            continue
        }

        if (-not $profile.AllowLocalFirewallRules) {
            $issues += "Firewall profile '$($profile.Name)' does not allow local firewall rules."
        }

        if (-not $profile.AllowInboundRules) {
            $issues += "Firewall profile '$($profile.Name)' is configured to disallow inbound rules."
        }
    }

    return $issues
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

$issues = New-Object System.Collections.Generic.List[string]
$expectedRemoteAddress = Get-ConfiguredRemoteAddress

try {
    $service = Get-Service -Name LanmanServer -ErrorAction Stop
    if ($service.Status -ne 'Running') {
        $issues.Add('LanmanServer is not running.')
    }
}
catch {
    $issues.Add('LanmanServer service was not found.')
}

if (-not (Test-AdminShareExists)) {
    $issues.Add('C$ administrative share was not found.')
}

$autoShareWks = Get-AutoShareSetting
if ($autoShareWks -eq 0) {
    $issues.Add('AutoShareWks is set to 0, which explicitly disables administrative shares.')
}

$ruleState = Get-FirewallRuleState -DisplayName $RuleName
if (-not $ruleState) {
    $issues.Add("Firewall rule '$RuleName' was not found.")
}
else {
    if ($ruleState.Description -ne $RuleDescription) {
        $issues.Add("Firewall rule '$RuleName' exists but is not managed by this solution.")
    }

    if ($ruleState.Enabled -ne 'True') {
        $issues.Add("Firewall rule '$RuleName' is not enabled.")
    }

    if ($ruleState.Direction -ne 'Inbound') {
        $issues.Add("Firewall rule '$RuleName' is not inbound.")
    }

    if ($ruleState.Action -ne 'Allow') {
        $issues.Add("Firewall rule '$RuleName' is not an allow rule.")
    }

    if ($ruleState.Protocol -ne 'TCP') {
        $issues.Add("Firewall rule '$RuleName' is not restricted to TCP.")
    }

    if ($ruleState.LocalPort -ne '445') {
        $issues.Add("Firewall rule '$RuleName' is not restricted to local TCP port 445.")
    }

    if ($ruleState.RemoteAddress -ne $expectedRemoteAddress) {
        $issues.Add("Firewall rule '$RuleName' RemoteAddress is '$($ruleState.RemoteAddress)' instead of '$expectedRemoteAddress'.")
    }
}

if (Get-Smb1Enabled) {
    $issues.Add('SMBv1 is enabled. This solution does not require or permit SMBv1.')
}

foreach ($issue in (Get-FirewallPolicyBlockers)) {
    $issues.Add($issue)
}

if ($issues.Count -gt 0) {
    foreach ($issue in $issues) {
        Write-DetectionMessage -Message $issue -Level 'ERROR'
    }

    exit 1
}

Write-DetectionMessage -Message 'Remote file access configuration is compliant.'
exit 0