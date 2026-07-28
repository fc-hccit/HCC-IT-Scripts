# Get current date
$currentDate = Get-Date

# Specify the number of months to check
$monthsThreshold = 12

# Convert threshold to a date for comparison
$thresholdDate = $currentDate.AddMonths(-$monthsThreshold)

# Exclude these profiles from being deleted
$excludedProfiles = @("Administrator", "Default", "Public", "DefaultAppPool", "la")

# Get all user profiles
$userProfiles = Get-WmiObject -Class Win32_UserProfile | Where-Object { 
    $_.Special -eq $false -and 
    $_.LocalPath -notlike "*SystemProfile*" -and 
    $excludedProfiles -notcontains $_.LocalPath.Split('\')[-1] 
}

# Loop through each profile
foreach ($profile in $userProfiles) {
    $lastUseTime = [Management.ManagementDateTimeConverter]::ToDateTime($profile.LastUseTime)
    
    if ($lastUseTime -lt $thresholdDate) {
        Write-Output "Deleting profile: $($profile.LocalPath)"
        try {
            # Delete the profile
            $profile.Delete()
        } catch {
            Write-Output "Error deleting profile: $($profile.LocalPath) - $_"
        }
    } else {
        Write-Output "Profile $($profile.LocalPath) is not older than 12 months."
    }
}
