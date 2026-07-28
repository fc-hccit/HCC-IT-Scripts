Function check-network{
$listBox1.Items.Clear()
$ListBox1.items.Add("Checking if wireless is switched on")

$Network = netsh wlan show network mode=ssid

if ($Network -like '*The wireless local area network interface is powered down*'){

$confirm = [System.Windows.Forms.MessageBox]::Show("Is your laptop in aeroplane mode?", 'Please Confirm', 'YesNo', 'Warning')

if ($confirm -eq 'Yes') {[System.Windows.Forms.MessageBox]::Show("Please exit aeroplane mode now and then press OK!", 'Please Confirm', 'OK', 'Warning')

check-network

}

if ($confirm -eq 'No') {[System.Windows.Forms.MessageBox]::Show("Please see the IT department", 'Please Confirm', 'OK', 'Warning')}}

elseif ($Network -like '*The Wireless AutoConfig Service (wlansvc) is not running.*'){

$ListBox1.items.Add("No wireless adapter detected")

Check-Internet

}

else {

$ListBox1.items.Add("Wireless is switched on")

$Network = netsh wlan show network mode=ssid

if ($Network -like '*Hope-Staff-WiFi*') {

$ListBox1.items.Add("Staff WiFi Available")

$SSID = netsh wlan show interfaces | select-string SSID

if ($SSID -like '*Hope-Staff-WiFi*') {

$ListBox1.items.Add("Already Connected To Staff WiFi")

Check-Internet

}}

else{[System.Windows.Forms.MessageBox]::Show("Your computer is not connected to the Staff WiFi network. Please connect now!", 'Please Confirm', 'OK', 'Warning')}

$State = netsh wlan show interfaces | Select-String State

if ($State -like '*disconnected*') { [System.Windows.Forms.MessageBox]::Show("Your computer is not connected to a WiFi network, Please connect now!", 'Please Confirm', 'OK', 'Warning')}

}}

Function Check-Internet{

$ListBox1.Items.Add("Testing internet connection...")

Start-Process "chrome.exe" "auth.localnetwork.zone"

$ListBox1.Items.Add("Checking authenticated login")

$cyber = [System.Windows.Forms.MessageBox]::Show("Can you access the Cyberhound login page?", 'Please Confirm', 'YesNo', 'Warning')

if ($cyber -eq 'Yes') {
$login =[System.Windows.Forms.MessageBox]::Show("Are you logged in?", 'Please Confirm', 'YesNo', 'Warning')

if ($login -eq 'Yes') {

Start-Process "chrome.exe" "www.hopecc.sa.edu.au"

$hope =[System.Windows.Forms.MessageBox]::Show("Has the Hope Christian College Website loaded?", 'Please Confirm', 'YesNo', 'Warning')

if ($hope -eq 'No') {$restart =[System.Windows.Forms.MessageBox]::Show("Your device may need a restart`n`nWould you like to restart now", 'Please Confirm', 'YesNo', 'Warning')}

if ($hope -eq 'Yes') {[System.Windows.Forms.MessageBox]::Show("Your internet connection seems to be working properly!", 'Please Confirm', 'OK', 'Warning')}
}}

if ($login -eq 'No') {[System.Windows.Forms.MessageBox]::Show("Please login and run the troubleshooter again", 'Please Confirm', 'OK', 'Warning')}

if ($cyber -eq 'No') {$restart =[System.Windows.Forms.MessageBox]::Show("Your device may need a restart`n`nWould you like to restart now", 'Please Confirm', 'YesNo', 'Warning')

if ($restart -eq 'Yes') {cmd.exe /c shutdown /r /t 30}
$ListBox1.Items.Add("Computer will restart in 30 seconds")
$ListBox1.Items.Add("Please save any open files")}

Start-Sleep 2

$ListBox1.Items.Add("Finished")
}

Function Google-Drive{
$listBox1.Items.Clear()
$ListBox1.Items.Add("Testing Google Drive...")
Start-sleep 1
$wshell = New-Object -ComObject Wscript.Shell
$key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6BBAE539-2232-434A-A4E5-9A33560C6283}'
$string = (Get-ItemProperty -Path $key -Name InstallLocation).InstallLocation

if(!(get-process "GoogleDriveFS" -ea SilentlyContinue)){
      
      $ListBox1.Items.Add("Google Drive isn't running!")
      
      Start-sleep 1 
      
      $wshell.Popup("  Your Google Drive isn't running!`n`n  Let's start it now.",10,"Oops!",48+4096)

      #Start GFS
      
      .$string
      
 }
 else {$ListBox1.Items.Add("Google Drive is Running")}
 
 Start-sleep 1

if (!(Test-Path -Path "G:\My Drive")) {
    
    $ListBox1.Items.Add("Google Drive isn't signed in!")   
    
    $wshell.Popup("  Please sign in to your Google Drive",10,"Oops!",48+4096)
    
    #Kill GFS 
    Stop-Process -Name "GoogleDriveFS" -Force
    #Start GFS
    .$string
            
    }  
else {$ListBox1.Items.Add("Google Drive Signed in")}

Start-sleep 1

$ListBox1.Items.Add("No problems detected")  }

Function student-password {

$listBox1.Items.Clear()
$ListBox1.Items.Add("Starting password reset utility...")
Start-Sleep 2


Function ResetPassword { 

$popup = New-Object -ComObject Wscript.Shell
$User = $ComboBox1.SelectedItem

    Set-ADAccountPassword -Identity $User -NewPassword (ConvertTo-SecureString -AsPlainText "hope1234" -Force)

$popup.Popup("$user's password has been successfully changed to hope1234",0,"Success",64+4096)
} 


#Get Users

$users = (Get-ADUser -Filter {Enabled -eq $TRUE} -SearchBase "OU=Students,DC=hopecc,DC=sa,DC=edu,DC=au").SamAccountName

#Start Form
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '300,50'
$Form.text                       = "Reset Student Password"
$Form.TopMost                    = $true
$Form.StartPosition              = "CenterScreen"

$Button1                         = New-Object system.Windows.Forms.Button

$Button1.width                   = 120
$Button1.height                  = 30
$Button1.location                = New-Object System.Drawing.Point(162,11)
$Button1.Font                    = 'Microsoft Sans Serif,10'
$Button1.Add_Click({ResetPassword})
$Button1.Enabled                 = $false

$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Student Name"
$ComboBox1.width                 = 130
$ComboBox1.height                = 30
ForEach($user in $users) {$combobox1.Items.Add($User)}
$combobox1.sorted                = $true
$combobox1.AutoCompleteMode      = 'Suggest'
$combobox1.AutoCompleteSource    = 'ListItems'
$ComboBox1.location              = New-Object System.Drawing.Point(14,14)
$ComboBox1.Font                  = 'Microsoft Sans Serif,10'
$ComboBox1.add_SelectedIndexChanged({ if($ComboBox1.SelectedIndex -ne "-1") {$Button1.Enabled = $true ; $Button1.text = "Reset Password"}})

$Form.controls.AddRange(@($Button1,$ComboBox1))

#Write your logic code here

[void]$Form.ShowDialog()


}

Function student-email {

$listBox1.Items.Clear()

$ListBox1.items.Add("Opening Google admin console...")

start-sleep 2

Start-Process "chrome.exe" "https://admin.google.com/ac/users?hl=en"

$ListBox1.items.Add("Find student using top search bar")

}

Function sound{
#Sound Device and Status

Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
    // f(), g(), ... are unused COM method slots. Define these if you care
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
    int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
    int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
    int f(); // Unused
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
    static IAudioEndpointVolume Vol()
    {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
        return epv;
    }
    public static float Volume
    {
        get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
    }
    public static bool Mute
    {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
    }
}
'@
$listBox1.Items.Clear()

$ListBox1.items.Add("Unmuting audio device")

[audio]::Mute = $false  # Set to $false to un-mute

Start-Sleep 1

$ListBox1.items.Add("Setting volume level to 100%")

[audio]::Volume  = 1.0 # 0.2 = 20%, etc.

Start-Sleep 1

$ListBox1.items.Add("Please test sound again...")
}

Function printing {

$listBox1.Items.Clear()
$ListBox1.items.Add("Updating user policy `nThis may take some time...")

#GP Update

cmd.exe /c gpupdate /force

$ListBox1.items.Add("Policy has been updated")

}

function Restart-Vivi{

$listBox1.Items.Clear()
$ListBox1.items.Add("Stopping Vivi...")

Stop-Process -Name "Vivi" -Force

Start-Sleep 5

$ListBox1.items.Add("Starting Vivi...")

Start-Process "C:\Program Files\Vivi Corporation\Vivi\Vivi.exe"

}


#Last Restart

$Lastrestart = (get-date) - (gcim Win32_OperatingSystem).LastBootUpTime | select days

$days = $Lastrestart -replace "\D" , ""

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = New-Object System.Drawing.Point(290,450)
$Form.text                       = "IT Troubleshooter"
$Form.TopMost                    = $True
$Form.StartPosition              = "CenterScreen"

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "I`'m having an issue with "
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(20,15)
$Label1.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',15,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))

$Button1                         = New-Object system.Windows.Forms.Button
$Button1.text                    = "Internet connectivity"
$Button1.width                   = 175
$Button1.height                  = 35
$Button1.location                = New-Object System.Drawing.Point(54,50)
$Button1.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button1.Add_Click({check-network})

$Button2                         = New-Object system.Windows.Forms.Button
$Button2.text                    = "Google Drive"
$Button2.width                   = 175
$Button2.height                  = 35
$Button2.location                = New-Object System.Drawing.Point(54,90)
$Button2.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button2.Add_Click({Google-Drive})

$Button3                         = New-Object system.Windows.Forms.Button
$Button3.text                    = "Student login password"
$Button3.width                   = 175
$Button3.height                  = 35
$Button3.location                = New-Object System.Drawing.Point(54,130)
$Button3.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button3.Add_Click({student-password})

$Button4                         = New-Object system.Windows.Forms.Button
$Button4.text                    = "Student email password"
$Button4.width                   = 175
$Button4.height                  = 35
$Button4.location                = New-Object System.Drawing.Point(54,170)
$Button4.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button4.Add_Click({student-email})

$Button5                         = New-Object system.Windows.Forms.Button
$Button5.text                    = "Vivi"
$Button5.width                   = 175
$Button5.height                  = 35
$Button5.location                = New-Object System.Drawing.Point(54,210)
$Button5.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button5.Add_Click({Restart-Vivi})

$Button6                         = New-Object system.Windows.Forms.Button
$Button6.text                    = "Printing"
$Button6.width                   = 175
$Button6.height                  = 35
$Button6.location                = New-Object System.Drawing.Point(54,250)
$Button6.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button6.Add_Click({printing})

$Button7                         = New-Object system.Windows.Forms.Button
$Button7.text                    = "Sound"
$Button7.width                   = 175
$Button7.height                  = 35
$Button7.location                = New-Object System.Drawing.Point(54,290)
$Button7.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$Button7.Add_Click({sound})

$ListBox1                        = New-Object system.Windows.Forms.ListBox
$ListBox1.text                   = "listBox"
$ListBox1.width                  = 174
$ListBox1.height                 = 85
$ListBox1.location               = New-Object System.Drawing.Point(54,330)

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Your device was last restarted $days days ago"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(25,420)
$Label2.Font                     = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
if($days -gt 5) {$Label2.ForeColor ="#d0021b"} 


$Form.controls.AddRange(@($Label1,$Button1,$Button2,$Button3,$Button4,$Button5,$Button6,$Button7,$ListBox1,$Label2))`




#Write your logic code here

[void]$Form.ShowDialog()


