# Variables
$username = $env:username
$computername = $env:computername
$path = "\\hopecc.sa.edu.au\Source\Files\Loan"
$logpath = "$path\$computername-$username*.log"
$date = Get-Date -format "dd-MM-yyyy"

function Show-BalloonTip {
    param(
        [string]$title,
        [string]$text,
        [string]$icon
    )

    switch ($icon) {
        "None" { $balloonTipIcon = [System.Windows.Forms.ToolTipIcon]::None }
        "Info" { $balloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info }
        "Warning" { $balloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning }
        "Error" { $balloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Error }
        Default { throw "Invalid value for icon: $icon" }
    }

    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.BalloonTipIcon = $balloonTipIcon
    $notifyIcon.BalloonTipTitle = $title
    $notifyIcon.BalloonTipText = $text
    $notifyIcon.Visible = $true
    $notifyIcon.ShowBalloonTip(0)
    
}

if (Test-Path $path) {

    # Check Local Admin

    if ($username -eq "la") {
        Write-Host "Local Admin is logged in"
    }
    else {
        if (Test-Path $logpath) {
            $content = Get-Content -Path "$path\$computername-$username*.log"
            $details = $content.Split()

            if ($Details[0] -match $date -and $Details[5] -like "day") {
                Show-BalloonTip -title "Loan Device" -text "This Loan Device must be returned to the IT office at the end of the day." -icon "info"
            }
            elseif ($Details[0] -notmatch $date -and $Details[5] -like "day") {
                Show-BalloonTip -title "Loan Expired" -text "Loan has expired." -icon "Warning"
                Start-Sleep -Seconds 5
                $null = Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,LockWorkStation"
            }
            elseif ($Details[5] -like "week") {
                $loanDate = [datetime]::ParseExact($Details[0], "dd-MM-yyyy", $null)
                $dateDifference = (Get-Date) - $loanDate

                if ($dateDifference.Days -le 7) {
                   $remainingDays = 7 - $dateDifference.Days
                    Show-BalloonTip -title "Loan Device" -text "This Loan Device must be returned to the IT office in $remainingDays days." -icon "info"
                }
                else {
                    Show-BalloonTip -title "Loan Expired" -text "Loan has expired." -icon "Warning"
                    Start-Sleep -Seconds 5
                    $null = Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,LockWorkStation"
                }
            }
        }
        else {
            Show-BalloonTip -title "Loan Error" -text "$computername has not been checked out to you." -icon "Warning"
            Start-Sleep -Seconds 5
            $null = Start-Process -FilePath "rundll32.exe" -ArgumentList "user32.dll,LockWorkStation"
        }
    }
}
else {
    Write-Host "Network not available"
}
