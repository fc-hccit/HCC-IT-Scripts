$ErrorActionPreference = 'Stop'

Import-Module ActiveDirectory -ErrorAction Stop

$ADServer = 'HCC-DC01.hopecc.sa.edu.au'
$CredentialPath = "$env:LOCALAPPDATA\StudentProvisioning\ADCred.xml"

if (Test-Path -LiteralPath $CredentialPath) {
    $ADCred = Import-Clixml -LiteralPath $CredentialPath
}
else {
    $ADCred = Get-Credential -Message 'Enter AD credentials (HOPECC\username)'

    if (-not $ADCred) {
        throw 'No AD credentials were provided.'
    }

    $CredentialFolder = Split-Path -Parent $CredentialPath
    New-Item -ItemType Directory -Path $CredentialFolder -Force | Out-Null
    $ADCred | Export-Clixml -LiteralPath $CredentialPath
}

$enabledUsers = Get-ADUser `
    -Filter 'Enabled -eq $true' `
    -Properties UserPrincipalName `
    -Server $ADServer `
    -Credential $ADCred `
    -ErrorAction Stop

$upnUppercaseCount = 0
$upnLowercaseCount = 0
$uppercaseUsers = [System.Collections.Generic.List[object]]::new()
$lowercaseUsers = [System.Collections.Generic.List[object]]::new()

foreach ($user in $enabledUsers) {
    $upn = [string]$user.UserPrincipalName

    if ($upn -match '^[^@]*service[^@]*@') {
        continue
    }

    if ($upn -notmatch '^[^@]*\.') {
        continue
    }

    $upnHasUppercase = $upn -cmatch '[A-Z]'
    $upnHasLowercase = $upn -cmatch '[a-z]'

    if ($upnHasUppercase) {
        $upnUppercaseCount++
        $uppercaseUsers.Add([PSCustomObject]@{
            SamAccountName     = $user.SamAccountName
            Name               = $user.Name
            UserPrincipalName  = $upn
            UppercaseInUPN     = $upnHasUppercase
        })
    }

    if ($upnHasLowercase -and -not $upnHasUppercase) {
        $upnLowercaseCount++
        $lowercaseUsers.Add([PSCustomObject]@{
            SamAccountName     = $user.SamAccountName
            Name               = $user.Name
            UserPrincipalName  = $upn
            LowercaseInUPN     = $upnHasLowercase
        })
    }
}

Write-Host "Enabled AD users checked: $($enabledUsers.Count)"
Write-Host "Enabled users with a period in the UPN name and uppercase in the UPN: $upnUppercaseCount"
Write-Host "Enabled users with a period in the UPN name and lowercase in the UPN: $upnLowercaseCount"

$DocumentsPath = [Environment]::GetFolderPath('MyDocuments')
$UppercaseCsvPath = Join-Path $DocumentsPath 'AD Uppercase UPN Report.csv'
$LowercaseCsvPath = Join-Path $DocumentsPath 'AD Lowercase UPN Report.csv'
$UppercaseCsvColumns = 'SamAccountName', 'Name', 'UserPrincipalName', 'UppercaseInUPN'
$LowercaseCsvColumns = 'SamAccountName', 'Name', 'UserPrincipalName', 'LowercaseInUPN'

if ($uppercaseUsers.Count -gt 0) {
    $uppercaseUsers |
        Select-Object $UppercaseCsvColumns |
        Export-Csv -LiteralPath $UppercaseCsvPath -NoTypeInformation -Encoding UTF8
}
else {
    '"SamAccountName","Name","UserPrincipalName","UppercaseInUPN"' |
        Set-Content -LiteralPath $UppercaseCsvPath -Encoding UTF8
}

if ($lowercaseUsers.Count -gt 0) {
    $lowercaseUsers |
        Select-Object $LowercaseCsvColumns |
        Export-Csv -LiteralPath $LowercaseCsvPath -NoTypeInformation -Encoding UTF8
}
else {
    '"SamAccountName","Name","UserPrincipalName","LowercaseInUPN"' |
        Set-Content -LiteralPath $LowercaseCsvPath -Encoding UTF8
}

Start-Process -FilePath $UppercaseCsvPath -ErrorAction Stop
Start-Process -FilePath $LowercaseCsvPath -ErrorAction Stop
Write-Host "Uppercase UPN CSV saved and opened: $UppercaseCsvPath"
Write-Host "Lowercase UPN CSV saved and opened: $LowercaseCsvPath"

if ($uppercaseUsers.Count -gt 0) {
    $uppercaseUsers |
        Sort-Object SamAccountName |
        Format-Table SamAccountName, Name, UserPrincipalName, UppercaseInUPN -AutoSize
}
