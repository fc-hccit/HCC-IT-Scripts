$cn = $env:computername
powercfg /batteryreport /output "\\hopecc.sa.edu.au\Source\Files\Battery\Battery Report\${cn}__battery_report.xml" /xml