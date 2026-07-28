$jobspath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs"
$jobs = Get-ChildItem -path $jobspath
$loanlist = @()

ForEach ($job in $jobs) {

If ($job -like "*L*_*") {$loanlist+=$job}


}
$loanlistlog = $loanlist.Name.trim(".log")
$loanlistloan = $loanlistlog.replace('_',' ').replace('L0','HCCLOAN').replace('L1','HCCLOAN1')
$loanlistformat = $loanlistloan | out-string
Send-MailMessage -From "Loan Report <alerts@hopecc.sa.edu.au>" -To "itstaff@hopecc.sa.edu.au" -Subject "The following loan devices are still borrowed out" -body "$loanlistformat"  -SmtpServer "aspmx.l.google.com" -ErrorAction SilentlyContinue
