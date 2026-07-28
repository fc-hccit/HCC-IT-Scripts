$wmi = Get-WmiObject -Class "BatteryStaticData" -Namespace "root\wmi"
$battery_design_capacity = $wmi.DesignedCapacity / 1000

$wmi = Get-WmiObject -Class "BatteryFullChargedCapacity" -Namespace "root\wmi"
$battery_full_charge_capacity = $wmi.FullChargedCapacity / 1000

$battery_health_percent = [math]::Round(($battery_full_charge_capacity / $battery_design_capacity) * 100)

Write-Host "Battery Health: $battery_health_percent%"