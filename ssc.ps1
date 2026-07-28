
# Define the frequency of screenshots (e.g., every 3 seconds)
$interval = 3

# Define the folder and fixed file name to save the screenshot
$savePath = "C:\users\public\RSSC\"
if (-Not (Test-Path $savePath)) {
    New-Item -ItemType Directory -Path $savePath
}
$fileName = "sstmp"
$filePath = Join-Path $savePath $fileName

# Infinite loop to continuously capture screenshots and overwrite the file
while ($true) {
    # Capture the screenshot
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $Bitmap = New-Object System.Drawing.Bitmap($Screen.Bounds.Width, $Screen.Bounds.Height)
    $Graphics = [System.Drawing.Graphics]::FromImage($Bitmap)
    $Graphics.CopyFromScreen($Screen.Bounds.Location, [System.Drawing.Point]::Empty, $Screen.Bounds.Size)

    # Set JPEG quality
    $jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.FormatID -eq [System.Drawing.Imaging.ImageFormat]::Jpeg.Guid }
    $qualityParam = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $qualityParam.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 50L) # 50% quality

    # Save and overwrite the screenshot as a low-quality JPEG
    $Bitmap.Save($filePath, $jpegEncoder, $qualityParam)
    $Bitmap.Dispose()

    # Sleep for the defined interval
    Start-Sleep -Seconds $interval
}
