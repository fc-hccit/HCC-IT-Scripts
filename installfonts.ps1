$FONTS = 0x14
$objShell = New-Object -ComObject Shell.Application
$objFolder = $objShell.Namespace($FONTS)
$wshell = New-Object -ComObject Wscript.Shell
$publicFontsPath = "C:\Users\Public\Fonts"
$systemFontsPath = "C:\Windows\Fonts"
$shortcutPath = "$publicFontsPath\Copy fonts into this folder to install.lnk"
$shell32Path = "$env:SystemRoot\system32\shell32.dll"
$iconIndex = 277
$shortcut = $wshell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $publicFontsPath
$shortcut.IconLocation = "$shell32Path,$iconIndex"
$shortcut.Save()

# Initialize variables
$publicFontsExist = $null
$initialPublicFontList = Get-ChildItem $publicFontsPath -Recurse -Include "*.ttf","*.otf","*.fnt"

$fontsExist = $initialPublicFontList.Count -gt 0

# Start the Fonts folder
Start-Process $publicFontsPath

Start-Sleep -Seconds 1

$null = (New-Object -ComObject WScript.Shell).AppActivate($publicFontsPath)

while (-not $fontsExist) {
    # Check for fonts in the Public Fonts folder
    $currentPublicFontList = Get-ChildItem $publicFontsPath -Recurse -Include "*.ttf","*.otf","*.fnt"
    $publicFontsExist = $currentPublicFontList.Count -gt 0

    if (-not $publicFontsExist) {
        # No fonts detected yet, wait for 5 seconds and check again
        Start-Sleep -Seconds 5
    } else {
        $fontsExist = $publicFontsExist
    }
}

# Initialize variables
$newFilesAdded = $true
$timeoutCount = 0

while ($newFilesAdded -and $timeoutCount -lt 24) {
    # Check for new font files in the Public Fonts folder
    $currentPublicFontList = Get-ChildItem $publicFontsPath -Recurse -Include "*.ttf","*.otf","*.fnt"

    $currentFontList = $currentPublicFontList

    if ($currentFontList.Count -eq $initialPublicFontList.Count) {
        # No new files added in the last 5 seconds
        $newFilesAdded = $false
    } else {
        # New files added, update the initial list and wait for 5 seconds
        $initialPublicFontList = $currentPublicFontList
        Start-Sleep -Seconds 5
        $timeoutCount++
    }
}

if ($timeoutCount -eq 24) {
    $wshell.Popup("Font installer timed out due to inactivity. Please try again!", 0, "Timeout", 48+4096)
} else {
    if ($currentPublicFontList.Count -eq 0) {
        $wshell.Popup("No new fonts to install.", 0, "Done", 64+4096)
    } else {
        $Question = "Do you want to install these fonts?"
        $install = $wshell.Popup($Question, 0, "Done", 4+4096)

        if ($install -eq 6) {
            Start-Sleep -Seconds 2

            foreach ($File in $currentPublicFontList) {
    $existingFontInPublic = Get-ChildItem (Join-Path $publicFontsPath $File.Name)
    $existingFontInWindows = Get-ChildItem (Join-Path $systemFontsPath $File.Name)

    # Check if the font file already exists in Windows Fonts directory
    if (!($existingFontInWindows)) {
        $objFolder.CopyHere($File.FullName, 0x10)
        Remove-Item $File
    } else {
        Write-Host "This Font already exists: $($File.Name)"
    }
}

            $wshell.Popup("Installing completed successfully!", 0, "Done")
        } else {
            $wshell.Popup("Installation Canceled!", 0, "Canceled", 16+4096)
        }
    }
}
