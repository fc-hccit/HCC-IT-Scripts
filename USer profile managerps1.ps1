# Load necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Define the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Profile List Viewer"
$form.Size = New-Object System.Drawing.Size(400, 300)

# Define a listbox to display profiles
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 10)
$listBox.Size = New-Object System.Drawing.Size(360, 200)
$form.Controls.Add($listBox)

# Define a button to refresh the list
$buttonRefresh = New-Object System.Windows.Forms.Button
$buttonRefresh.Location = New-Object System.Drawing.Point(10, 220)
$buttonRefresh.Size = New-Object System.Drawing.Size(100, 30)
$buttonRefresh.Text = "Refresh"
$buttonRefresh.Add_Click({
    Refresh-List
})
$form.Controls.Add($buttonRefresh)

# Define a button to show SID and user profile path
$buttonShowDetails = New-Object System.Windows.Forms.Button
$buttonShowDetails.Location = New-Object System.Drawing.Point(120, 220)
$buttonShowDetails.Size = New-Object System.Drawing.Size(150, 30)
$buttonShowDetails.Text = "Show Details"
$buttonShowDetails.Add_Click({
    Show-Details
})
$form.Controls.Add($buttonShowDetails)

# Function to refresh the list on form load
function Refresh-List {
    $listBox.Items.Clear()
    $global:profiles = Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\*' |
                    ForEach-Object { Get-ItemProperty $_.PSPath } |
                    Where-Object { 
                        $_.ProfileImagePath -notlike '*\.NET*' -and     # Exclude profiles containing ".NET"
                        $_.ProfileImagePath -notlike '*\ServiceProfiles*' -and  # Exclude AppPool service profiles
                        $_.ProfileImagePath -notlike '*AppPool*' -and
                        $_.ProfileImagePath -notlike '*\System*'   # Exclude System profiles
                    } |
                    Select-Object PSChildName, ProfileImagePath

    foreach ($profile in $profiles) {
        $username = (Split-Path $profile.ProfileImagePath -Leaf)
        $listBox.Items.Add("$username")
    }
}

# Function to show SID and user profile path
function Show-Details {
    $selectedUser = $listBox.SelectedItem

    if ($selectedUser -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select a user first.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $profile = $global:profiles | Where-Object { $_.ProfileImagePath -like "*\Users\$selectedUser" }
    
    $username = (Split-Path $profile.ProfileImagePath -Leaf)
    $sidPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($profile.PSChildName)"
    $sid = (Get-ItemProperty -Path $sidPath).PSChildName
    $profilePath = $profile.ProfileImagePath

    [System.Windows.Forms.MessageBox]::Show("Username: $username`r`nSID: $sid`r`nProfile Path: $profilePath", "User Details", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Add event handler for form load
$form.add_Load({
    Refresh-List
})

# Define a button to delete selected user profile
$buttonDelete = New-Object System.Windows.Forms.Button
$buttonDelete.Location = New-Object System.Drawing.Point(280, 220)
$buttonDelete.Size = New-Object System.Drawing.Size(90, 30)
$buttonDelete.Text = "Delete"
$buttonDelete.Add_Click({
    Delete-Profile
})
$form.Controls.Add($buttonDelete)

# Function to take ownership of the profile folder and its contents using Set-Acl
function Take-Ownership {
    param (
        [string]$path
    )

    try {
        # Get the current ACL
        $acl = Get-Acl $path

        # Get the identity of the currently logged-in user
        $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

        # Add full control permissions for the current user
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentIdentity.Name,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        $acl.AddAccessRule($rule)

        # Set the modified ACL
        Set-Acl -Path $path -AclObject $acl
    } catch {
        Write-Host "Failed to take ownership: $_"
    }
}

# Function to delete selected user profile
function Delete-Profile {
    $selectedUser = $listBox.SelectedItem

    if ($selectedUser -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select a user first.", "Information", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    
    $profile = $global:profiles | Where-Object { $_.ProfileImagePath -like "*\Users\$selectedUser" }

  
    if ($profile -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Failed to retrieve profile details for the selected user.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $sidPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$($profile.PSChildName)"
    $profilePath = $profile.ProfileImagePath

   # Take ownership of the profile folder and its contents
    Take-Ownership -path $profilePath

    # Remove the registry key
    Remove-Item -Path $sidPath -Force -Recurse

    # Remove the profile folder
    Remove-Item -Path $profilePath -Force -Recurse

    # Refresh the list after deletion
    Refresh-List

    [System.Windows.Forms.MessageBox]::Show("Profile deleted successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

# Display the form
$form.ShowDialog()
