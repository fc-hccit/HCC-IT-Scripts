$downloadsfiles = "C:\Users\Admin\Downloads\*.*" 
$downloads = "C:\Users\Admin\Downloads\"  
$files = Get-ChildItem -Path $downloadsfiles
$files
foreach ($file in $files)
{ [System.IO.Path]::GetExtension($file) | ForEach-Object { 

if(!(Test-Path -Path $downloads\$_ )){
    New-Item -Name $_ -Path $downloads -ItemType directory
    Move-Item -Path $downloads\*$_ -destination $downloads\$_ 
}
Else { 
Move-Item -Path $downloads\*$_ -destination $downloads\$_ 
}
} 
}
