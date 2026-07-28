# Define the path where screenshots will be stored
$screenshotPath = "C:\Screenshots"
# Define the retention period in days
$retentionDays = 14
# Define the interval between checks in seconds
$interval = 60
# Define the idle threshold in seconds (e.g., 300 seconds = 5 minutes)
$idleThreshold = 300

# Ensure the screenshot directory exists
if (-not (Test-Path $screenshotPath)) {
    New-Item -Path $screenshotPath -ItemType Directory
}

# Define the LASTINPUTINFO structure
Add-Type @"
    using System;
    using System.Runtime.InteropServices;

    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    public static class UserInput {
        [DllImport("user32.dll")]
        public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

        public static int GetIdleTime() {
            LASTINPUTINFO lastInputInfo = new LASTINPUTINFO();
            lastInputInfo.cbSize = (uint)Marshal.SizeOf(lastInputInfo);
            GetLastInputInfo(ref lastInputInfo);
            return ((Environment.TickCount & int.MaxValue) - (int)lastInputInfo.dwTime) / 1000;
        }
    }
"@

# Function to get the idle time of the system
function Get-IdleTime {
    return [UserInput]::GetIdleTime()
}

# Function to capture a screenshot
function Take-Screenshot {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $fileName = "$screenshotPath\$timestamp"  # No extension

    # Capture the screenshot and save it without an extension
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $screenBounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object Drawing.Bitmap $screenBounds.Width, $screenBounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($screenBounds.Location, [System.Drawing.Point]::Empty, $screenBounds.Size)

    # Set JPEG quality to low (50%)
    $quality = 50
    $jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
    $bitmap.Save($fileName, $jpegEncoder, $encoderParameters)

    $bitmap.Dispose()
    $graphics.Dispose()
}

# Function to clean up old screenshots
function Cleanup-Screenshots {
    $cutoffDate = (Get-Date).AddDays(-$retentionDays)
    Get-ChildItem -Path $screenshotPath -Filter "*" | Where-Object { $_.CreationTime -lt $cutoffDate } | Remove-Item
}

# Main loop to take screenshots only when the device is in use
while ($true) {
    $idleTime = Get-IdleTime

    # Take a screenshot only if the device is in use (idle time is less than the threshold)
    if ($idleTime -lt $idleThreshold) {
        Take-Screenshot
    }

    # Clean up old screenshots
    Cleanup-Screenshots

    # Wait before checking again
    Start-Sleep -Seconds $interval
}
