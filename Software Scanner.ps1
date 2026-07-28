Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework

# Function to get installed applications
function Get-InstalledApplications {
    $apps = @()

    # Get installed apps from the registry (32-bit and 64-bit)
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    
    foreach ($path in $paths) {
        $apps += Get-ItemProperty $path -ErrorAction SilentlyContinue | 
            Select-Object DisplayName, DisplayVersion, InstallLocation
    }
    
    # Filter out apps with no DisplayName or version
    $apps = $apps | Where-Object { $_.DisplayName -and $_.DisplayVersion }
    
    return $apps
}

# Function to get .NET Framework versions
function Get-NetFrameworkVersions {
    $netFrameworks = @()

    $regKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse |
        Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
        Where-Object { $_.Version -match "^\d" }

    foreach ($key in $regKeys) {
        $netFrameworks += [PSCustomObject]@{
            DisplayName    = ".NET Framework " + $key.PSChildName
            DisplayVersion = $key.Version
            InstallLocation = "N/A"
        }
    }

    return $netFrameworks
}

# Function to get installed Visual C++ Redistributables
function Get-VCppRedistributables {
    $vcpp = @()

    $vcppKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\VisualStudio\VC\Runtimes\" |
        Get-ItemProperty -Name Version -ErrorAction SilentlyContinue

    foreach ($key in $vcppKeys) {
        $vcpp += [PSCustomObject]@{
            DisplayName    = "Visual C++ Redistributable " + $key.PSChildName
            DisplayVersion = $key.Version
            InstallLocation = "N/A"
        }
    }

    return $vcpp
}

# Function to get application versions in the folder C:\Windows\hcccache
function Get-HccCacheAppVersions {
    $folderPath = "C:\Windows\hcccache"
    $appFiles = @()

    if (Test-Path $folderPath) {
        # Get all .exe and .dll files in the folder
        $files = Get-ChildItem -Path $folderPath -Filter *.exe,*.dll -Recurse

        foreach ($file in $files) {
            $versionInfo = (Get-Item $file.FullName).VersionInfo

            if ($versionInfo -and $versionInfo.FileVersion) {
                $appFiles += [PSCustomObject]@{
                    DisplayName    = $file.Name
                    DisplayVersion = $versionInfo.FileVersion
                    InstallLocation = $file.FullName
                }
            }
        }
    }

    return $appFiles
}

# Function to show installed applications, system software, and files in C:\Windows\hcccache
function Show-InstalledAppsGui {
    $apps = Get-InstalledApplications
    $netFrameworks = Get-NetFrameworkVersions
    $vcppRedistributables = Get-VCppRedistributables
    $hccCacheApps = Get-HccCacheAppVersions

    # Combine all software data
    $allSoftware = $apps + $netFrameworks + $vcppRedistributables + $hccCacheApps

    # Create a new Windows form
    $form = New-Object system.Windows.Forms.Form
    $form.Text = "Installed Applications and System Software"
    $form.Size = New-Object System.Drawing.Size(1000,600)
    
    # Create a DataGridView to display the list of applications
    $dataGridView = New-Object System.Windows.Forms.DataGridView
    $dataGridView.Size = New-Object System.Drawing.Size(970,500)
    $dataGridView.Location = New-Object System.Drawing.Point(10,10)
    $dataGridView.AutoSizeColumnsMode = 'Fill'
    
    # Create a DataTable to store the application data
    $dataTable = New-Object System.Data.DataTable
    $dataTable.Columns.Add("Application Name")
    $dataTable.Columns.Add("Version")
    $dataTable.Columns.Add("Install Path")
    
    # Populate the DataTable with app and system software data
    foreach ($app in $allSoftware) {
        $row = $dataTable.NewRow()
        $row["Application Name"] = $app.DisplayName
        $row["Version"] = $app.DisplayVersion
        $row["Install Path"] = $app.InstallLocation
        $dataTable.Rows.Add($row)
    }
    
    # Bind the DataTable to the DataGridView
    $dataGridView.DataSource = $dataTable

    # Add the DataGridView to the form
    $form.Controls.Add($dataGridView)

    # Add a button to close the form
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(450,520)
    $closeButton.Add_Click({
        $form.Close()
    })
    
    $form.Controls.Add($closeButton)
    
    # Show the form
    $form.ShowDialog()
}

Show-InstalledAppsGui
