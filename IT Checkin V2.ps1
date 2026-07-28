$file = "C:\inetpub\wwwroot\signins.csv"
$prevWriteTime = (Get-Item $file).LastWriteTime
$dest = "\\LAdmin-pc\wwwroot\Jobs"

while ($true) {
    $currWriteTime = (Get-Item $file).LastWriteTime
    if ($currWriteTime -ne $prevWriteTime) {
        $prevWriteTime = $currWriteTime
        $allLines = Get-Content $file 
        $bottom4lines = $allLines[-4..-1]
        $name = $bottom4lines[0]
        $teacher = $bottom4lines[1]
        $issue = $bottom4lines[2]
        $date = $bottom4lines[3]          
        $fileName = "$date $name.log"
        $data = "$date $name $teacher"
        $data | Out-File -FilePath "$dest\$filename"
        $issue = $combobox2.Text
        # Student
        $studentname = $name.text.Split(".")
        $studentfirst = $studentname[0]
        $studentlast = $studentname[1]
        # Staff
        $staffname = $teacher.text.Split(".")
        $stafffirst = $staffname[0]
        $stafflast = $staffname[1]
        Send-MailMessage -From "IT Support <itsupport@hopecc.sa.edu.au>" -To "$stafffirst.$stafflast@hopecc.sa.edu.au" -Subject "$studentfirst $studentlast checked into the IT Office" -Body "Hi $stafffirst, `n`n$studentfirst $studentlast just checked into the IT Office with the following issue: $issue.`n`nWe will send them back to class as soon as possible and update you concerning the outcome." -SmtpServer "aspmx.l.google.com"
    }
    Start-Sleep -Seconds 2
}