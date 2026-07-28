Function Get-Folder($initialDirectory)

{
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms")|Out-Null

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

Get-Folder

Get-ChildItem "$folder" -Recurse -Filter "*.inf" | 
ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }
