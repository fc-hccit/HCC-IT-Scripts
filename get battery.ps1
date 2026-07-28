# Define the path to your HTML file
$htmlFilePath = "C:\Users\ITMGR-ND\Desktop\battery-report.html"

# Read the content of the HTML file
$htmlContent = Get-Content -Path $htmlFilePath -Raw

# Define the start and end markers
$startMarker1 = "Power states over the last 3 days"
$endMarker1 = "Battery drains over the last 3 days"

# Extract content between the markers
$startIndex = $htmlContent.IndexOf($startMarker1)
$endIndex = $htmlContent.IndexOf($endMarker1)

if ($startIndex -ne -1 -and $endIndex -ne -1 -and $startIndex -lt $endIndex) {
    $extractedContent = $htmlContent.Substring($startIndex, $endIndex - $startIndex)
    
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
        # Check for merged date and time
        if ($line -match '^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})$') {
            # Extract date and time
            $date = $matches[1]
            $time = $matches[2]

            # Add date and time as separate items to the processed array
            $processedArray += $date
            $processedArray += $time
        } elseif ($line -match '^\d{2}:\d{2}:\d{2}$') {
            # Add time entries as separate items
            $processedArray += $line
        } elseif ($line -match '^\d+ %$') {
            # Add percentage entries as separate items
            $processedArray += $line
        }
    }

    # Output the array items (for debugging purposes, if needed)
    Write-Output "Filtered content as separate array items:"
    Write-Output $processedArray
}
