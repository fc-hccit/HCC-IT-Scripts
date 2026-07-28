Function Refresh-ListView {
    $ListView.Items.Clear()
    $appList = Get-AppxPackage | Sort-Object Name  # Sort the apps alphabetically by Name
    foreach ($app in $appList) {
        $item = New-Object Windows.Forms.ListViewItem
        $item.Text = $app.Name
        $ListView.Items.Add($item)
    }
}


Function Remove-SelectedApps {
    $selectedApps = $ListView.Items | Where-Object { $_.Checked -eq $true }
    foreach ($app in $selectedApps) {
        $appName = $app.Text
        Get-AppxPackage "*$appName*" | Remove-AppxPackage
        Write-Host "Removed app: $appName"
    }
}

Function Search-Apps {
    $searchQuery = $SearchTextBox.Text
    $ListView.Items.Clear()
    Get-AppxPackage | Where-Object { $_.Name -like "*$searchQuery*" } | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem
        $item.Text = $_.Name
        $ListView.Items.Add($item)
    }
}

Function Search-Apps-EnterKey {
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        Search-Apps
    }
}

Function Toggle-Select-All {
    $selectAllText = "Select All"
    $deselectAllText = "Deselect All"

    if ($SelectAllButton.Text -eq $selectAllText) {
        $SelectAllButton.Text = $deselectAllText
        $ListView.Items | ForEach-Object { $_.Checked = $true }
    } else {
        $SelectAllButton.Text = $selectAllText
        $ListView.Items | ForEach-Object { $_.Checked = $false }
    }
}

$Form = New-Object Windows.Forms.Form
$Form.Text = "Store App Remover"
$Form.Size = New-Object Drawing.Size(600, 600)
$Form.TopMost = $true

# Create a GroupBox for the App List
$GroupBox = New-Object Windows.Forms.GroupBox
$GroupBox.Location = New-Object Drawing.Point(10, 10)
$GroupBox.Size = New-Object Drawing.Size(570, 400)
$GroupBox.Text = "App List"
$Form.Controls.Add($GroupBox)

# Place ListView inside the GroupBox
$ListView = New-Object Windows.Forms.ListView
$ListView.Location = New-Object Drawing.Point(10, 20)
$ListView.Size = New-Object Drawing.Size(550, 330)
$ListView.CheckBoxes = $true
$ListView.View = [System.Windows.Forms.View]::Details
$ListView.Columns.Add("App Name", 250)
$GroupBox.Controls.Add($ListView)

# Create a separate GroupBox for the control buttons
$ControlGroupBox = New-Object Windows.Forms.GroupBox
$ControlGroupBox.Location = New-Object Drawing.Point(10, 420)
$ControlGroupBox.Size = New-Object Drawing.Size(570, 100)
$ControlGroupBox.Text = "Actions"
$Form.Controls.Add($ControlGroupBox)

$RefreshButton = New-Object Windows.Forms.Button
$RefreshButton.Location = New-Object Drawing.Point(10, 20)
$RefreshButton.Size = New-Object Drawing.Size(100, 30)
$RefreshButton.Text = "Refresh"
$RefreshButton.Add_Click({ Refresh-ListView })
$ControlGroupBox.Controls.Add($RefreshButton)

$RemoveButton = New-Object Windows.Forms.Button
$RemoveButton.Location = New-Object Drawing.Point(120, 20)
$RemoveButton.Size = New-Object Drawing.Size(100, 30)
$RemoveButton.Text = "Remove Selected"
$RemoveButton.Add_Click({ Remove-SelectedApps })
$ControlGroupBox.Controls.Add($RemoveButton)

$SearchTextBox = New-Object Windows.Forms.TextBox
$SearchTextBox.Location = New-Object Drawing.Point(230, 20)
$SearchTextBox.Size = New-Object Drawing.Size(150, 30)
$SearchTextBox.Add_KeyDown({ Search-Apps-EnterKey $_ })
$ControlGroupBox.Controls.Add($SearchTextBox)

$SearchButton = New-Object Windows.Forms.Button
$SearchButton.Location = New-Object Drawing.Point(390, 20)
$SearchButton.Size = New-Object Drawing.Size(60, 30)
$SearchButton.Text = "Search"
$SearchButton.Add_Click({ Search-Apps })
$ControlGroupBox.Controls.Add($SearchButton)

$SelectAllButton = New-Object Windows.Forms.Button
$SelectAllButton.Location = New-Object Drawing.Point(460, 20)
$SelectAllButton.Size = New-Object Drawing.Size(100, 30)
$SelectAllButton.Text = "Select All"
$SelectAllButton.Add_Click({ Toggle-Select-All })
$ControlGroupBox.Controls.Add($SelectAllButton)
$null = Refresh-ListView
$Form.ShowDialog()
