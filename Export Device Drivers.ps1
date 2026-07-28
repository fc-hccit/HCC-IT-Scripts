$ModelName = (Get-WmiObject -Class Win32_ComputerSystem).Model
$ScriptDirectory = $PSScriptRoot

if ([string]::IsNullOrEmpty($ScriptDirectory)) {
    $ScriptDirectory = (Get-Location).Path
}

$Destination = Join-Path -Path $ScriptDirectory -ChildPath $ModelName
Export-WindowsDriver -Online -Destination $Destination