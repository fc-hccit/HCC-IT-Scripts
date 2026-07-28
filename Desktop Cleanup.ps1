$desktopfiles = "C:\Users\Admin\Desktop\*.*" 
$desktop = "C:\Users\Admin\Desktop\"  
$files = Get-ChildItem -Path $desktopfiles -Exclude *.lnk
$files
foreach ($file in $files)
{ [System.IO.Path]::GetExtension($file) | ForEach-Object { 

if(!(Test-Path -Path $Desktop\$_ )){
    New-Item -Name $_ -Path $desktop -ItemType directory
    Move-Item -Path $Desktop\*$_ -destination $Desktop\$_ 
}
Else { 
Move-Item -Path $Desktop\*$_ -destination $Desktop\$_ 
}
} 
}
