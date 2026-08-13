[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System

[System.Windows.Forms.Application]::EnableVisualStyles()

function ConvertTo-PlainText {
    param(
        [Parameter(Mandatory = $true)]
        [Security.SecureString]$SecureString
    )

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Write-Status {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $statusTextBox.AppendText("[$timestamp] [$Level] $Message$([Environment]::NewLine)")
    $statusTextBox.SelectionStart = $statusTextBox.TextLength
    $statusTextBox.ScrollToCaret()
}

function Write-StatusSafe {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    if ($form.InvokeRequired) {
        $callback = [System.Action[string, string]]{
            param($statusMessage, $statusLevel)
            Write-Status -Message $statusMessage -Level $statusLevel
        }
        $null = $form.BeginInvoke($callback, @($Message, $Level))
        return
    }

    Write-Status -Message $Message -Level $Level
}

function Set-ButtonsEnabled {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enabled
    )

    if ($form.InvokeRequired) {
        $callback = [System.Action[bool]]{
            param($buttonsEnabled)
            Set-ButtonsEnabled -Enabled $buttonsEnabled
        }
        $null = $form.BeginInvoke($callback, @($Enabled))
        return
    }

    foreach ($button in @($testButton, $connectButton, $openButton, $disconnectButton)) {
        $button.Enabled = $Enabled
    }
}

function Get-TargetComputerName {
    $computerName = $computerNameTextBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($computerName)) {
        throw 'Enter a computer name first.'
    }

    return $computerName
}

function Get-SharePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    return "\\$ComputerName\C$"
}

function Get-DefaultUserName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $userName = $userNameTextBox.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($userName)) {
        return "$ComputerName\Administrator"
    }

    if ($userName -match '^[^\\]+\\[^\\]+$' -or $userName -match '^[^@]+@[^@]+$') {
        return $userName
    }

    return "$ComputerName\$userName"
}

function Test-Port445 {
    $computerName = Get-TargetComputerName
    Write-Status -Message "Testing TCP 445 on $computerName."
    Set-ButtonsEnabled -Enabled $false

    $null = [System.Threading.Tasks.Task]::Run([System.Action]{
        $tcpClient = $null

        try {
            $tcpClient = [System.Net.Sockets.TcpClient]::new()
            $connectTask = $tcpClient.ConnectAsync($computerName, 445)
            $completedInTime = $connectTask.Wait(3000)

            if (-not $completedInTime) {
                Write-StatusSafe -Message "TCP 445 test to $computerName timed out after 3 seconds." -Level 'ERROR'
                return
            }

            if ($tcpClient.Connected) {
                Write-StatusSafe -Message "TCP 445 is reachable on $computerName."
            }
            else {
                Write-StatusSafe -Message "TCP 445 is not reachable on $computerName." -Level 'ERROR'
            }
        }
        catch {
            Write-StatusSafe -Message "TCP 445 test failed for ${computerName}: $($_.Exception.Message)" -Level 'ERROR'
        }
        finally {
            if ($tcpClient) {
                $tcpClient.Dispose()
            }

            Set-ButtonsEnabled -Enabled $true
        }
    })
}

function Remove-ExistingShareSession {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $sharePath = Get-SharePath -ComputerName $ComputerName

    try {
        $mapping = Get-SmbMapping -RemotePath $sharePath -ErrorAction SilentlyContinue
        if ($mapping) {
            Remove-SmbMapping -RemotePath $sharePath -Force -ErrorAction Stop | Out-Null
            Write-Status -Message "Removed existing SMB mapping for $sharePath."
        }
    }
    catch {
        Write-Status -Message "Could not remove existing SMB mapping for ${sharePath}: $($_.Exception.Message)" -Level 'WARN'
    }
}

function Connect-AdminShare {
    $computerName = Get-TargetComputerName
    $sharePath = Get-SharePath -ComputerName $computerName
    $credentialUserName = Get-DefaultUserName -ComputerName $computerName

    Write-Status -Message "Prompting for credentials for $credentialUserName."
    $credential = Get-Credential -UserName $credentialUserName -Message "Enter the LAPS-managed local administrator password for $computerName"

    if (-not $credential) {
        Write-Status -Message 'Connection cancelled at credential prompt.' -Level 'WARN'
        return
    }

    if ($clearSessionCheckBox.Checked) {
        Remove-ExistingShareSession -ComputerName $computerName
    }

    $plainTextPassword = ConvertTo-PlainText -SecureString $credential.Password

    try {
        New-SmbMapping -RemotePath $sharePath -UserName $credential.UserName -Password $plainTextPassword -Persistent:$false -ErrorAction Stop | Out-Null
        Write-Status -Message "Connected to $sharePath as $($credential.UserName)."
        Start-Process explorer.exe $sharePath
    }
    catch {
        Write-Status -Message "Failed to connect to ${sharePath}: $($_.Exception.Message)" -Level 'ERROR'
    }
    finally {
        if ($plainTextPassword) {
            $plainTextPassword = $null
        }
    }
}

function Open-AdminShare {
    $computerName = Get-TargetComputerName
    $sharePath = Get-SharePath -ComputerName $computerName

    Write-Status -Message "Opening $sharePath."
    Start-Process explorer.exe $sharePath
}

function Disconnect-AdminShare {
    $computerName = Get-TargetComputerName
    $sharePath = Get-SharePath -ComputerName $computerName

    try {
        Remove-SmbMapping -RemotePath $sharePath -Force -ErrorAction Stop | Out-Null
        Write-Status -Message "Disconnected $sharePath."
    }
    catch {
        Write-Status -Message "No active SMB mapping found for $sharePath, or disconnect failed: $($_.Exception.Message)" -Level 'WARN'
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Remote File Access Connector'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(820, 560)
$form.MinimumSize = New-Object System.Drawing.Size(820, 560)
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(700, 30)
$titleLabel.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 16)
$titleLabel.Text = 'Connect to a workstation C$ share'

$computerNameLabel = New-Object System.Windows.Forms.Label
$computerNameLabel.Location = New-Object System.Drawing.Point(20, 70)
$computerNameLabel.Size = New-Object System.Drawing.Size(140, 22)
$computerNameLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$computerNameLabel.Text = 'Computer name'

$computerNameTextBox = New-Object System.Windows.Forms.TextBox
$computerNameTextBox.Location = New-Object System.Drawing.Point(170, 68)
$computerNameTextBox.Size = New-Object System.Drawing.Size(540, 30)
$computerNameTextBox.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$userNameLabel = New-Object System.Windows.Forms.Label
$userNameLabel.Location = New-Object System.Drawing.Point(20, 110)
$userNameLabel.Size = New-Object System.Drawing.Size(140, 22)
$userNameLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$userNameLabel.Text = 'Local admin account'

$userNameTextBox = New-Object System.Windows.Forms.TextBox
$userNameTextBox.Location = New-Object System.Drawing.Point(170, 108)
$userNameTextBox.Size = New-Object System.Drawing.Size(540, 30)
$userNameTextBox.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$userNameTextBox.Text = 'Administrator'

$userHintLabel = New-Object System.Windows.Forms.Label
$userHintLabel.Location = New-Object System.Drawing.Point(170, 140)
$userHintLabel.Size = New-Object System.Drawing.Size(540, 34)
$userHintLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$userHintLabel.Text = 'Enter only the account name to use COMPUTERNAME\account, or enter a full username if needed.'

$clearSessionCheckBox = New-Object System.Windows.Forms.CheckBox
$clearSessionCheckBox.Location = New-Object System.Drawing.Point(170, 180)
$clearSessionCheckBox.Size = New-Object System.Drawing.Size(540, 24)
$clearSessionCheckBox.Font = New-Object System.Drawing.Font('Segoe UI', 9)
$clearSessionCheckBox.Text = 'Clear any existing SMB session to this computer before connecting'
$clearSessionCheckBox.Checked = $true

$testButton = New-Object System.Windows.Forms.Button
$testButton.Location = New-Object System.Drawing.Point(20, 230)
$testButton.Size = New-Object System.Drawing.Size(160, 38)
$testButton.Text = 'Test TCP 445'
$testButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$testButton.Add_Click({
    try {
        Test-Port445
    }
    catch {
        Write-Status -Message $_.Exception.Message -Level 'ERROR'
    }
})

$connectButton = New-Object System.Windows.Forms.Button
$connectButton.Location = New-Object System.Drawing.Point(200, 230)
$connectButton.Size = New-Object System.Drawing.Size(160, 38)
$connectButton.Text = 'Connect and Open C$'
$connectButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$connectButton.Add_Click({
    try {
        Connect-AdminShare
    }
    catch {
        Write-Status -Message $_.Exception.Message -Level 'ERROR'
    }
})

$openButton = New-Object System.Windows.Forms.Button
$openButton.Location = New-Object System.Drawing.Point(380, 230)
$openButton.Size = New-Object System.Drawing.Size(160, 38)
$openButton.Text = 'Open Existing Session'
$openButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$openButton.Add_Click({
    try {
        Open-AdminShare
    }
    catch {
        Write-Status -Message $_.Exception.Message -Level 'ERROR'
    }
})

$disconnectButton = New-Object System.Windows.Forms.Button
$disconnectButton.Location = New-Object System.Drawing.Point(560, 230)
$disconnectButton.Size = New-Object System.Drawing.Size(160, 38)
$disconnectButton.Text = 'Disconnect'
$disconnectButton.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$disconnectButton.Add_Click({
    try {
        Disconnect-AdminShare
    }
    catch {
        Write-Status -Message $_.Exception.Message -Level 'ERROR'
    }
})

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Location = New-Object System.Drawing.Point(20, 295)
$statusLabel.Size = New-Object System.Drawing.Size(160, 22)
$statusLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10)
$statusLabel.Text = 'Status'

$statusTextBox = New-Object System.Windows.Forms.TextBox
$statusTextBox.Location = New-Object System.Drawing.Point(20, 325)
$statusTextBox.Size = New-Object System.Drawing.Size(760, 180)
$statusTextBox.Multiline = $true
$statusTextBox.ReadOnly = $true
$statusTextBox.ScrollBars = 'Vertical'
$statusTextBox.Font = New-Object System.Drawing.Font('Consolas', 10)

$form.Controls.AddRange(@(
    $titleLabel,
    $computerNameLabel,
    $computerNameTextBox,
    $userNameLabel,
    $userNameTextBox,
    $userHintLabel,
    $clearSessionCheckBox,
    $testButton,
    $connectButton,
    $openButton,
    $disconnectButton,
    $statusLabel,
    $statusTextBox
))

$form.Add_Shown({
    $computerNameTextBox.Focus()
    Write-Status -Message 'Enter a target computer name, test TCP 445, then connect with the existing LAPS-managed local administrator credential.'
})

[void]$form.ShowDialog()