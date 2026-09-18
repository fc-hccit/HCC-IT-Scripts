Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll")]
    public static extern short GetAsyncKeyState(int vKey);
}
"@

# Define the path to your sound file
$soundFilePath = "C:\Users\Luke T\Downloads\h20.wav"

# Create a new SoundPlayer object
$soundPlayer = New-Object System.Media.SoundPlayer
$soundPlayer.SoundLocation = $soundFilePath

# Key code for the "Pause/Break" key
$keyCodePauseBreak = 0x13

while ($true) {
    # Check if the "Pause/Break" key is pressed
    $keyState = [User32]::GetAsyncKeyState($keyCodePauseBreak)
    
    if ($keyState -ne 0) {
        # Play the sound
        $soundPlayer.Play()
        
        # Add a small delay to avoid multiple detections
        #Start-Sleep -Milliseconds 500
    }

    # Add a small delay to reduce CPU usage
    Start-Sleep -Milliseconds 100
}