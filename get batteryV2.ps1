# Define the Battery report path

$batteryreport = "C:\Users\Public\Documents\battery-report.html"

# Generate the Battery report

start-process "C:\Windows\System32\powercfg.exe" -ArgumentList "/batteryreport /output $batteryreport"

start-sleep 5

if (!(Test-Path $batteryreport)){write-host "No report file generated" ; return} 


# Read the content of the HTML file
$htmlContent = Get-Content -Path $reportPath -Raw

# Define the start and end markers
$startMarker1 = "Power states over the last 3 days"
$endMarker1 = "Battery drains over the last 3 days"

# Extract content between the markers
$startIndex = $htmlContent.IndexOf($startMarker1)
$endIndex = $htmlContent.IndexOf($endMarker1)

if ($startIndex -ne -1 -and $endIndex -ne -1 -and $startIndex -lt $endIndex) {
    $extractedContent = $htmlContent.Substring($startIndex + $startMarker1.Length, $endIndex - ($startIndex + $startMarker1.Length))
    
    # Remove HTML tags using a simple regex
    $cleanedContent = $extractedContent -replace '<[^>]+>', ''

    # Filter and format content
    $filteredContentArray = $cleanedContent -split "`r`n" | ForEach-Object {
        $_.Trim() # Trim leading and trailing whitespace
    } | Where-Object {
        $_ -notmatch "mWh" -and
        $_ -notmatch "Report generated" -and
        $_ -notmatch "Battery" -and
        $_ -notmatch "Active" -and
        $_ -notmatch "suspended" -and
        $_ -notmatch "Connected standby" -and
        $_ -notmatch "START TIME" -and
        $_ -notmatch "STATE" -and
        $_ -notmatch "AC" -and
        $_ -notmatch "SOURCE" -and
        $_ -notmatch "CAPACITY REMAINING"
    } | Where-Object { $_ -ne "" }  # Remove blank lines

    # Initialize an array to store processed items
    $processedArray = @()

    # Process each line
    foreach ($line in $filteredContentArray) {
        # Remove all spaces from each item
        $line = $line -replace '\s+', '' # Replace all whitespace characters

        # Check for merged date and time
        if ($line -match '^(\d{4}-\d{2}-\d{2})(\d{2}:\d{2}:\d{2})$') {
            # Extract date and time
            $date = $matches[1]
            $time = $matches[2]

            # Add date and time as separate items to the processed array
            $processedArray += $date
            $processedArray += $time
        } elseif ($line -match '^\d{2}:\d{2}:\d{2}$') {
            # Add time entries as separate items
            $processedArray += $line
        } elseif ($line -match '^\d+%$') {
            # Add percentage entries as separate items
            $processedArray += $line
        }
    }

  
}

# Define a function to check if a time is after 9 AM
function Is-AfterNineAM {
    param (
        [string]$time
    )
    return [datetime]::ParseExact($time, "HH:mm:ss", $null).TimeOfDay -gt [timespan]::Parse("08:59:59")
}

# Define the date to search for
$searchDate = (Get-Date).ToString("yyyy-MM-dd")

# Initialize variables
$currentDate = $null
$currentTime = $null
$found = $false

for ($i = 0; $i -lt $processedArray.Count -and -not $found; $i++) {
    if ($processedArray[$i] -match '^\d{4}-\d{2}-\d{2}$') {
        # Date entry
        $currentDate = $processedArray[$i]
        $currentTime = $null # Reset time when a new date is encountered
    } elseif ($processedArray[$i] -match '^\d{2}:\d{2}:\d{2}$') {
        # Time entry
        if ($currentDate -eq $searchDate -and (Is-AfterNineAM -time $processedArray[$i])) {
            $currentTime = $processedArray[$i]
        }
    } elseif ($processedArray[$i] -match '^\d+%$') {
        # Percentage entry
        if ($currentDate -eq $searchDate -and $currentTime) {
            # Output the first found result
            Write-Output "Date: $currentDate"
            Write-Output "Time: $currentTime"
            Write-Output "Percentage: $($processedArray[$i])"
            $found = $true # Stop further processing
        }
    }
}

if (-not $found) {
    Write-Output "No matching data found for date $searchDate."
}

