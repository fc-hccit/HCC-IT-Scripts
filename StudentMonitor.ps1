$watcher = New-Object System.IO.FileSystemWatcher
$watcher.IncludeSubdirectories = $true
$watcher.Path = '\\hopecc.sa.edu.au\Source\Files\Student Jobs'
$watcher.EnableRaisingEvents = $true
$action =
{
    $path = $event.SourceEventArgs.FullPath
    $changetype = $event.SourceEventArgs.ChangeType
    Write-Host "$path was $changetype at $(get-date)"
    $PlayWav=New-Object System.Media.SoundPlayer
    $PlayWav.SoundLocation=’C:\StudentMonitor\dingdong.wav’
    $PlayWav.playsync()
}
Register-ObjectEvent $watcher 'Created' -Action $action
#while ($true){Start-sleep 999}