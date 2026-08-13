# ============================================================
# Require Administrator
# ============================================================

$principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    try {
        Start-Process powershell.exe `
            -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
            -Verb RunAs

        exit
    }
    catch {
        Add-Type -AssemblyName System.Windows.Forms

        [System.Windows.Forms.MessageBox]::Show(
            "Administrator privileges are required to run this tool.",
            "Windows Hello Troubleshooter",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )

        exit
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------
# Windows Hello / TPM / BitLocker Troubleshooter
# ------------------------------------------------------------

[System.Windows.Forms.Application]::EnableVisualStyles()

# ---------- Helpers ----------

function Add-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $Message`r`n")
    $txtLog.SelectionStart = $txtLog.TextLength
    $txtLog.ScrollToCaret()
}

function Run-Command {
    param([scriptblock]$Command)

    try {
        & $Command 2>&1 | Out-String
    }
    catch {
        $_.Exception.Message
    }
}

function Get-TPMStatus {

    try {
        $tpm = Get-Tpm

        return [PSCustomObject]@{
            Present = $tpm.TpmPresent
            Ready   = $tpm.TpmReady
            Enabled = $tpm.TpmEnabled
            Activated = $tpm.TpmActivated
        }
    }
    catch {
        return $null
    }
}

function Get-BitLockerStatus {

    try {
        $osDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive

        return [PSCustomObject]@{
            Protection = $osDrive.ProtectionStatus
            Encryption = $osDrive.VolumeStatus
            Percentage = $osDrive.EncryptionPercentage
        }
    }
    catch {
        return $null
    }
}

function Get-NGCStatus {

    $ngc = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"

    if (Test-Path $ngc) {

        try {
            $items = Get-ChildItem $ngc -Force -ErrorAction SilentlyContinue

            return [PSCustomObject]@{
                Exists = $true
                Items  = $items.Count
                Path   = $ngc
            }
        }
        catch {
            return [PSCustomObject]@{
                Exists = $true
                Items  = -1
                Path   = $ngc
            }
        }
    }

    return [PSCustomObject]@{
        Exists = $false
        Items  = 0
        Path   = $ngc
    }
}

# ---------- GUI ----------

$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Hello / TPM Troubleshooter"
$form.Size = New-Object System.Drawing.Size(900,720)
$form.StartPosition = "CenterScreen"
$form.Font = New-Object System.Drawing.Font("Segoe UI",10)

# Header

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Windows Hello / TPM Troubleshooter"
$lblTitle.Font = New-Object System.Drawing.Font("Segoe UI",18,[System.Drawing.FontStyle]::Bold)
$lblTitle.Location = New-Object System.Drawing.Point(20,15)
$lblTitle.Size = New-Object System.Drawing.Size(800,40)
$form.Controls.Add($lblTitle)

$lblSubtitle = New-Object System.Windows.Forms.Label
$lblSubtitle.Text = "Designed for PIN failures following BIOS / BitLocker / TPM changes"
$lblSubtitle.Location = New-Object System.Drawing.Point(22,55)
$lblSubtitle.Size = New-Object System.Drawing.Size(800,25)
$form.Controls.Add($lblSubtitle)

# Status group

$grpStatus = New-Object System.Windows.Forms.GroupBox
$grpStatus.Text = "System Status"
$grpStatus.Location = New-Object System.Drawing.Point(20,90)
$grpStatus.Size = New-Object System.Drawing.Size(840,170)
$form.Controls.Add($grpStatus)

# TPM

$lblTPM = New-Object System.Windows.Forms.Label
$lblTPM.Text = "TPM:"
$lblTPM.Location = New-Object System.Drawing.Point(20,30)
$lblTPM.Size = New-Object System.Drawing.Size(100,25)
$grpStatus.Controls.Add($lblTPM)

$txtTPM = New-Object System.Windows.Forms.Label
$txtTPM.Text = "Not checked"
$txtTPM.Location = New-Object System.Drawing.Point(130,30)
$txtTPM.Size = New-Object System.Drawing.Size(300,25)
$grpStatus.Controls.Add($txtTPM)

# BitLocker

$lblBL = New-Object System.Windows.Forms.Label
$lblBL.Text = "BitLocker:"
$lblBL.Location = New-Object System.Drawing.Point(20,65)
$lblBL.Size = New-Object System.Drawing.Size(100,25)
$grpStatus.Controls.Add($lblBL)

$txtBL = New-Object System.Windows.Forms.Label
$txtBL.Text = "Not checked"
$txtBL.Location = New-Object System.Drawing.Point(130,65)
$txtBL.Size = New-Object System.Drawing.Size(500,25)
$grpStatus.Controls.Add($txtBL)

# NGC

$lblNGC = New-Object System.Windows.Forms.Label
$lblNGC.Text = "Hello NGC:"
$lblNGC.Location = New-Object System.Drawing.Point(20,100)
$lblNGC.Size = New-Object System.Drawing.Size(100,25)
$grpStatus.Controls.Add($lblNGC)

$txtNGC = New-Object System.Windows.Forms.Label
$txtNGC.Text = "Not checked"
$txtNGC.Location = New-Object System.Drawing.Point(130,100)
$txtNGC.Size = New-Object System.Drawing.Size(500,25)
$grpStatus.Controls.Add($txtNGC)

# Diagnosis

$lblDiagnosis = New-Object System.Windows.Forms.Label
$lblDiagnosis.Text = "Diagnosis:"
$lblDiagnosis.Location = New-Object System.Drawing.Point(20,135)
$lblDiagnosis.Size = New-Object System.Drawing.Size(100,25)
$grpStatus.Controls.Add($lblDiagnosis)

$txtDiagnosis = New-Object System.Windows.Forms.Label
$txtDiagnosis.Text = "Run diagnostics"
$txtDiagnosis.Location = New-Object System.Drawing.Point(130,135)
$txtDiagnosis.Size = New-Object System.Drawing.Size(680,25)
$grpStatus.Controls.Add($txtDiagnosis)

# ---------- Buttons ----------

$btnCheck = New-Object System.Windows.Forms.Button
$btnCheck.Text = "Run Diagnostics"
$btnCheck.Location = New-Object System.Drawing.Point(20,280)
$btnCheck.Size = New-Object System.Drawing.Size(180,45)
$form.Controls.Add($btnCheck)

$btnRepair = New-Object System.Windows.Forms.Button
$btnRepair.Text = "Repair Windows Hello"
$btnRepair.Location = New-Object System.Drawing.Point(215,280)
$btnRepair.Size = New-Object System.Drawing.Size(180,45)
$form.Controls.Add($btnRepair)

$btnPIN = New-Object System.Windows.Forms.Button
$btnPIN.Text = "Open PIN Settings"
$btnPIN.Location = New-Object System.Drawing.Point(410,280)
$btnPIN.Size = New-Object System.Drawing.Size(180,45)
$form.Controls.Add($btnPIN)

$btnTPM = New-Object System.Windows.Forms.Button
$btnTPM.Text = "Open TPM Console"
$btnTPM.Location = New-Object System.Drawing.Point(605,280)
$btnTPM.Size = New-Object System.Drawing.Size(180,45)
$form.Controls.Add($btnTPM)

$btnReport = New-Object System.Windows.Forms.Button
$btnReport.Text = "Export Report"
$btnReport.Location = New-Object System.Drawing.Point(20,335)
$btnReport.Size = New-Object System.Drawing.Size(180,40)
$form.Controls.Add($btnReport)

$btnReboot = New-Object System.Windows.Forms.Button
$btnReboot.Text = "Restart Computer"
$btnReboot.Location = New-Object System.Drawing.Point(215,335)
$btnReboot.Size = New-Object System.Drawing.Size(180,40)
$form.Controls.Add($btnReboot)

# ---------- Log ----------

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Text = "Diagnostic Log"
$lblLog.Location = New-Object System.Drawing.Point(20,395)
$lblLog.Size = New-Object System.Drawing.Size(200,25)
$form.Controls.Add($lblLog)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Multiline = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.ReadOnly = $true
$txtLog.Location = New-Object System.Drawing.Point(20,425)
$txtLog.Size = New-Object System.Drawing.Size(840,210)
$form.Controls.Add($txtLog)

# ---------- Diagnostics ----------

$btnCheck.Add_Click({

    $txtLog.Clear()

    Add-Log "Starting Windows Hello diagnostics..."
    Add-Log "Computer: $env:COMPUTERNAME"
    Add-Log "User: $env:USERNAME"
    Add-Log "OS: $([System.Environment]::OSVersion.Version)"

    # TPM

    Add-Log "Checking TPM..."

    $tpm = Get-TPMStatus

    if ($null -eq $tpm) {

        $txtTPM.Text = "ERROR - TPM information unavailable"
        $txtTPM.ForeColor = [System.Drawing.Color]::Red

        Add-Log "ERROR: Could not query TPM."

    }
    elseif (-not $tpm.Present) {

        $txtTPM.Text = "FAILED - TPM not detected"
        $txtTPM.ForeColor = [System.Drawing.Color]::Red

        Add-Log "TPM is not detected."

    }
    elseif (-not $tpm.Ready) {

        $txtTPM.Text = "WARNING - TPM not ready"
        $txtTPM.ForeColor = [System.Drawing.Color]::Red

        Add-Log "TPM detected but NOT READY."

    }
    else {

        $txtTPM.Text = "OK - TPM present and ready"
        $txtTPM.ForeColor = [System.Drawing.Color]::Green

        Add-Log "TPM is present and ready."
    }

    # BitLocker

    Add-Log "Checking BitLocker..."

    $bl = Get-BitLockerStatus

    if ($null -eq $bl) {

        $txtBL.Text = "Unable to query BitLocker"
        $txtBL.ForeColor = [System.Drawing.Color]::Red

        Add-Log "Could not query BitLocker."

    }
    else {

        $txtBL.Text = "$($bl.Encryption) / $($bl.Percentage)% encrypted / Protection: $($bl.Protection)"

        if ($bl.Protection -eq "On") {
            $txtBL.ForeColor = [System.Drawing.Color]::Green
        }
        else {
            $txtBL.ForeColor = [System.Drawing.Color]::Orange
        }

        Add-Log "BitLocker: $($bl.Encryption)"
        Add-Log "Encryption: $($bl.Percentage)%"
        Add-Log "Protection: $($bl.Protection)"
    }

    # NGC

    Add-Log "Checking Windows Hello NGC..."

    $ngc = Get-NGCStatus

    if (-not $ngc.Exists) {

        $txtNGC.Text = "NGC folder does not exist"
        $txtNGC.ForeColor = [System.Drawing.Color]::Orange

        Add-Log "NGC folder does not exist."

    }
    else {

        $txtNGC.Text = "NGC exists - $($ngc.Items) item(s)"
        $txtNGC.ForeColor = [System.Drawing.Color]::Green

        Add-Log "NGC folder exists."
        Add-Log "NGC items: $($ngc.Items)"
    }

    # Diagnosis

    if ($null -ne $tpm -and -not $tpm.Present) {

        $txtDiagnosis.Text = "TPM NOT DETECTED - check BIOS/UEFI TPM settings."

    }
    elseif ($null -ne $tpm -and -not $tpm.Ready) {

        $txtDiagnosis.Text = "TPM NOT READY - investigate TPM/BIOS state before resetting PIN."

    }
    elseif ($null -ne $tpm -and $tpm.Ready) {

        $txtDiagnosis.Text = "TPM OK - Windows Hello/NGC is the likely issue."

    }
    else {

        $txtDiagnosis.Text = "Unable to determine diagnosis."

    }

    Add-Log "Diagnostics complete."
})

# ---------- Repair Hello ----------

$btnRepair.Add_Click({

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "This will rebuild the Windows Hello NGC container.`r`n`r`n" +
        "The user will need to create a new Windows Hello PIN afterwards.`r`n`r`n" +
        "This does NOT clear the TPM.`r`n`r`n" +
        "Continue?",
        "Repair Windows Hello",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    Add-Log "Starting Windows Hello repair..."

    $ngc = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"

    try {

        Add-Log "Taking ownership of NGC..."

        takeown.exe /f $ngc /r /d y | Out-Null

        Add-Log "Granting Administrators access..."

        icacls.exe $ngc /grant administrators:F /t /c | Out-Null

        Add-Log "Removing NGC contents..."

        Get-ChildItem $ngc -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

        Add-Log "NGC repair completed."

        [System.Windows.Forms.MessageBox]::Show(
            "Windows Hello has been rebuilt.`r`n`r`n" +
            "Restart the computer and create a new PIN.",
            "Repair Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )

    }
    catch {

        Add-Log "ERROR: $($_.Exception.Message)"

        [System.Windows.Forms.MessageBox]::Show(
            "Repair failed:`r`n`r`n$($_.Exception.Message)",
            "Repair Failed",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
})

# ---------- PIN Settings ----------

$btnPIN.Add_Click({

    Add-Log "Opening Windows Sign-in Options..."

    Start-Process "ms-settings:signinoptions"
})

# ---------- TPM Console ----------

$btnTPM.Add_Click({

    Add-Log "Opening TPM Management Console..."

    Start-Process "tpm.msc"
})

# ---------- Export Report ----------

$btnReport.Add_Click({

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = "Text files (*.txt)|*.txt"
    $dialog.FileName = "$env:COMPUTERNAME-WindowsHelloReport.txt"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

        $report = @()

        $report += "WINDOWS HELLO / TPM TROUBLESHOOTING REPORT"
        $report += "============================================"
        $report += ""
        $report += "Computer: $env:COMPUTERNAME"
        $report += "User: $env:USERNAME"
        $report += "Date: $(Get-Date)"
        $report += ""

        $report += "TPM"
        $report += "---"

        try {
            $report += (Get-Tpm | Format-List | Out-String)
        }
        catch {
            $report += "Unable to query TPM"
        }

        $report += ""
        $report += "BITLOCKER"
        $report += "---------"

        try {
            $report += (Get-BitLockerVolume -MountPoint $env:SystemDrive |
                Format-List | Out-String)
        }
        catch {
            $report += "Unable to query BitLocker"
        }

        $report += ""
        $report += "WINDOWS HELLO"
        $report += "-------------"

        $ngcPath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\Microsoft\NGC"

        $report += "NGC Path: $ngcPath"
        $report += "NGC Exists: $(Test-Path $ngcPath)"

        $report += ""
        $report += "DIAGNOSTIC LOG"
        $report += "--------------"
        $report += $txtLog.Text

        $report | Out-File $dialog.FileName -Encoding UTF8

        Add-Log "Report exported to $($dialog.FileName)"

        [System.Windows.Forms.MessageBox]::Show(
            "Report saved successfully.",
            "Export Complete",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    }
})

# ---------- Restart ----------

$btnReboot.Add_Click({

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "Restart the computer now?",
        "Restart",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {

        Restart-Computer
    }
})

# ---------- Initial message ----------

Add-Log "Ready."
Add-Log "Click 'Run Diagnostics' to check TPM, BitLocker and Windows Hello."
Add-Log "IMPORTANT: Do not clear the TPM unless the BitLocker recovery key is confirmed."

$form.ShowDialog() | Out-Null