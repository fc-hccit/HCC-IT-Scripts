$processName = "ARMSvc"

# Check if the process is running
$process = Get-Process -Name $processName -ErrorAction SilentlyContinue

if ($process) {
    # If the process is running, get its CPU usage
    $cpuUsage = (Get-Counter "\Process($processName*)\% Processor Time").CounterSamples.CookedValue
    Write-Host "$processName is running. CPU Usage: $($cpuUsage.ToString('P'))"
} else {
    Write-Host "$processName is not running."
}
