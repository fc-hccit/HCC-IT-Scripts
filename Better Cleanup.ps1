[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Position = 0)]
    [string]$Path = "$env:USERPROFILE\Desktop"
)

$ResolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
$TargetPath = $ResolvedPath.Path

$categories = @{
    Executables = @('*.exe', '*.msi', '*.msu')
    Images      = @('*.jpg', '*.jpeg', '*.png', '*.gif', '*.ico')
    Archives    = @('*.zip', '*.rar', '*.7z', '*.iso')
    Documents   = @('*.docx', '*.pdf', '*.xlsx', '*.csv', '*.txt', '*.rtf')
    Video       = @('*.mp4', '*.avi', '*.webm', '*.mkv', '*.mov')
    Scripts     = @('*.bat', '*.ps1', '*.vbs', '*.js', '*.cmd')
    Audio       = @('*.mp3', '*.wav', '*.mid', '*.m4a', '*.aif')
    Web         = @('*.htm', '*.html', '*.aspx', '*.asp', '*.xml')
}

$files = Get-ChildItem -Path $TargetPath -File -ErrorAction SilentlyContinue
if (-not $files) {
    Write-Verbose "No files found in $TargetPath."
    return
}

foreach ($category in $categories.GetEnumerator()) {
    $destinationFolder = Join-Path -Path $TargetPath -ChildPath $category.Key
    $matchedFiles = $files | Where-Object {
        foreach ($pattern in $category.Value) {
            if ($_.Name -like $pattern) {
                return $true
            }
        }
        return $false
    }
    
    if (-not $matchedFiles) {
        continue
    }

    if (-not (Test-Path -Path $destinationFolder)) {
        if ($PSCmdlet.ShouldProcess($destinationFolder, 'Create directory')) {
            New-Item -Path $destinationFolder -ItemType Directory -Force | Out-Null
        }
    }

    foreach ($file in $matchedFiles) {
        $destination = Join-Path -Path $destinationFolder -ChildPath $file.Name
        if (Test-Path -Path $destination) {
            $destination = Join-Path -Path $destinationFolder -ChildPath ("{0}_{1}{2}" -f $file.BaseName, (Get-Date -Format 'yyyyMMddHHmmss'), $file.Extension)
        }

        if ($PSCmdlet.ShouldProcess($file.FullName, "Move to $destinationFolder")) {
            Move-Item -Path $file.FullName -Destination $destination -ErrorAction Stop
            Write-Verbose "Moved '$($file.Name)' to '$destinationFolder'."
        }
    }
}
 
