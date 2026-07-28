$repdir = "\\hopecc.sa.edu.au\Source\Files\Battery\Battery Report"
$reports = Get-ChildItem $repdir -recurse


foreach ($report in $reports) { 

[xml]$xmlAttr = Get-Content -Path $repdir\$report

$CompName = $xmlAttr.BatteryReport.SystemInformation.ComputerName
$Dcap = $xmlAttr.BatteryReport.Batteries.Battery.DesignCapacity
$Fcap = $xmlAttr.BatteryReport.Batteries.Battery.FullChargeCapacity
$health = ($Fcap/$Dcap).tostring("P")
$CSVOBJ = [pscustomobject]@{'Computer Name' = $CompName; 'Design Capacity' = $Dcap; 'Full Capacity' = $Fcap; 'Health Percentage' = $health}
$CSVOBJ | Export-Csv -Path "\\hopecc.sa.edu.au\Source\Files\Battery\Battery Report\Full Report.csv" -Append

}