$FromAddress = "alerts@hopecc.sa.edu.au" # Enter your email address here
$ToAddress = "matthew.morton@hopecc.sa.edu.au" # Enter the recipient's email address here
$SMTPServer = "aspmx.l.google.com" # Enter the SMTP server address here
$SMTPPort = "25" # Enter the SMTP port number here

$LogFile = "C:\LogonLog.txt" # Enter the path and name of the log file here
$LastLogon = Get-Date
$Subject = "User logon notification"

function Send-LogonNotificationEmail {
    $Body = "The user $env:USERNAME logged on to computer $($env:COMPUTERNAME) at $(Get-Date)"
    Send-MailMessage -From $FromAddress -To $ToAddress -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Port $SMTPPort
}

# Check if log file exists and if not, create it
if(!(Test-Path $LogFile)) {
    New-Item -ItemType File -Path $LogFile | Out-Null
}

# Get the last logon date from the log file
$LastLogon = Get-Content $LogFile | Select-Object -Last 1

# If the last logon was before today, send the email notification and update the log file
if($LastLogon -lt (Get-Date).Date) {
    Send-LogonNotificationEmail
    Add-Content $LogFile (Get-Date)
}
