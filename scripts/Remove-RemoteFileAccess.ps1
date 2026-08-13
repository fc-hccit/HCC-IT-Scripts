#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$RuleName = 'College IT - SMB Admin'
$RuleDescription = 'Created by Deploy-RemoteFileAccess.ps1 for restricted administrative SMB access over TCP 445.'
$SolutionRoot = Join-Path -Path $env:ProgramData -ChildPath 'CollegeIT\RemoteFileAccess'
$LogDirectory = Join-Path -Path $SolutionRoot -ChildPath 'Logs'
$StateDirectory = Join-Path -Path $SolutionRoot -ChildPath 'State'
$StateFile = Join-Path -Path $StateDirectory -ChildPath 'RemoteFileAccess-State.json'
$LogFile = Join-Path -Path $LogDirectory -ChildPath ('Remove-RemoteFileAccess-{0}.log' -f (Get-Date -Format 'yyyyMMdd-HHmmss'))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

function Import-DeploymentState {
    if (Test-Path -Path $StateFile) {
        return Get-Content -Path $StateFile -Raw | ConvertFrom-Json
    }

    return $null
}

function Convert-StartupModeForSetService {
    param(
        [Parameter(Mandatory = $true)]
        [string]$StartMode
    )

    switch ($StartMode) {
        'Auto' { return 'Automatic' }
        'Automatic' { return 'Automatic' }
        'Manual' { return 'Manual' }
        'Disabled' { return 'Disabled' }
        default { throw "Unsupported LanmanServer startup mode '$StartMode' in state file." }
    }
}

Initialize-Directories
Write-Log -Message 'Starting Remove-RemoteFileAccess.ps1'

$state = Import-DeploymentState
$managedRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue | Select-Object -First 1

if ($managedRule) {
    if ($managedRule.Description -eq $RuleDescription) {
        Write-Log -Message ("Removing firewall rule '$RuleName'.")
        $managedRule | Remove-NetFirewallRule
    }
    else {
        Write-Log -Message ("A firewall rule named '$RuleName' exists but is not tagged as managed by this solution. It was left unchanged.") -Level 'WARN'
    }
}
else {
    Write-Log -Message ("Firewall rule '$RuleName' was not present.")
}

if ($state) {
    if ($state.LanmanServerStartupChangedByDeploy -and $state.LanmanServerOriginalStartMode) {
        Write-Log -Message ("Restoring LanmanServer startup type to {0}." -f $state.LanmanServerOriginalStartMode)
        Set-Service -Name LanmanServer -StartupType (Convert-StartupModeForSetService -StartMode $state.LanmanServerOriginalStartMode)
    }

    if ($state.LanmanServerStartedByDeploy -and $state.LanmanServerOriginalState -ne 'Running') {
        Write-Log -Message 'Stopping LanmanServer because this deployment started it and it was originally not running.'
        Stop-Service -Name LanmanServer -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $StateFile -Force -ErrorAction SilentlyContinue
}
else {
    Write-Log -Message 'No deployment state file was found. No service state will be changed.' -Level 'WARN'
}

Write-Log -Message 'Rollback completed.'
exit 0