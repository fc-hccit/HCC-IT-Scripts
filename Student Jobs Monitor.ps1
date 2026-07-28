$lastCheckTime = Get-Date
$folderPath = "\\hopecc.sa.edu.au\source\Files\Student Jobs"
$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.Visible = $true
$counter = 0
$notification.add_BalloonTipClicked({
    $jobProcess = Get-Process -name "Student Jobs" -ErrorAction SilentlyContinue

    if ($jobProcess -eq $null) {
        Start-Process -FilePath "Student Jobs"
    }
    else {
$signature = @"
[DllImport("user32.dll")]
public static extern bool SetForegroundWindow(IntPtr hWnd);

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
"@
$setForegroundWindow = Add-Type -MemberDefinition $signature -Name 'Win32SetForegroundWindow' -Namespace 'Win32Functions' -PassThru
$jobProcess | ForEach-Object {
    $setForegroundWindow::SetForegroundWindow($_.MainWindowHandle) | Out-Null
    $setForegroundWindow::ShowWindow($_.MainWindowHandle, 1) | Out-Null
}
}
})


while ($true) {
   
    $files = Get-ChildItem $folderPath | Where-Object { $_.Name -notmatch '^L|#' -and $_.LastWriteTime -gt $lastCheckTime }

    if ($files) {
        
        Add-Type -AssemblyName presentationCore
            $mediaPlayer = New-Object system.windows.media.mediaplayer
            $mediaPlayer.open('C:\StudentMonitor\dingdong.wav')
            $mediaPlayer.Play()
           
    }
    # Check for Open Jobs
    if ($counter -eq 6) {
    
    Write-Host "Checking for Open Jobs"
    
    $files = Get-ChildItem $folderPath
     
        foreach($file in $files){ 
        
            if( $file.Name -notmatch '^L|#' -and (Get-ItemProperty $folderPath\$file).LastWriteTime -lt (Get-Date).AddMinutes(-5) ){Write-Host "New Job Detected" ; $newjob = $true}
            else{Write-Host "Old Job"} 
        }
        $newjob
        if($newjob){$notification.ShowBalloonTip(5000, "Please respond", "There are still jobs requiring a response!", [System.Windows.Forms.ToolTipIcon]::Info)}
        $newjob = $false
        $counter = 0
        }
        
        $lastCheckTime = Get-Date
        
        $counter++

    # Wait for some time before checking again
    Start-Sleep -Seconds 5
    
    Write-Host "Checking $counter Times "
}


