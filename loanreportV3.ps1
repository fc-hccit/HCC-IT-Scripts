$jobspath = "\\hopecc.sa.edu.au\Source\Files\Student Jobs"
$jobs = Get-ChildItem -path $jobspath
$loanlist = @()
$currentDate = Get-Date

ForEach ($job in $jobs) {
    If ($job -like "*L*_*") {
        $jobname = $Job.name
        $split1 = $jobname.Split()[0]
        $split2 = $split1.split('_')
        $date = [datetime]::ParseExact($split2[1], 'dd-MM-yyyy', $null)
        $daysDifference = ($currentdate - $Date).Days

        # Color codes based on days difference
        $color = ""
        If ($daysDifference -lt 7) {
            $color = "Green"
        } ElseIf ($daysDifference -lt 14) {
            $color = "Orange"
        } Else {
            $color = "Red"
        }

        $loanlist += "<p><font color='$color'>$jobname out for <b>$daysDifference</b> Days</font></p>"
    }
}

$loanlistlog = $loanlist.replace('.log','')
$loanlistloan = $loanlistlog.replace('_',' ').replace('L0','HCCLOAN').replace('L1','HCCLOAN1')
$loanlistformat = $loanlistloan -join ""

$body = @"
<html>
<body>
$loanlistformat
</body>
</html>
"@

Send-MailMessage -From "Loan Report <alerts@hopecc.sa.edu.au>" -To "itstaff@hopecc.sa.edu.au" -Subject "The following loan devices are still borrowed out" -Body $body -BodyAsHtml -SmtpServer "aspmx.l.google.com" -ErrorAction SilentlyContinue
