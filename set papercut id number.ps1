# PaperCut server URL and auth token
$uri = 'http://hcc-ps01:9191/rpc/api/xmlrpc'
$authToken = 'jh$NraX8XOyN#GQ2'

# Prompt for target username and card number
$targetUser = Read-Host "Enter target username"
$cardNumber = Read-Host "Enter card number"

# Function to call XML-RPC methods
function Call-PaperCutApi($methodName, $paramsXml) {
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<methodCall>
  <methodName>$methodName</methodName>
  <params>
$paramsXml
  </params>
</methodCall>
"@

    $response = Invoke-WebRequest -Uri $uri -Method Post -Body $xml -ContentType 'text/xml' -UseBasicParsing
    return $response.Content
}

# Build params XML for api.lookupUserNameByCardNo
$lookupParams = @"
    <param><value><string>$authToken</string></value></param>
    <param><value><string>$cardNumber</string></value></param>
"@

# Check if card is already assigned
$lookupResponse = Call-PaperCutApi 'api.lookUpUserNameByCardNo' $lookupParams

# Extract username from response (simple string extraction)
$assignedUser = ($lookupResponse -replace '.*<string>(.*)</string>.*','$1').Trim()

if ($assignedUser -and $assignedUser -ne $targetUser) {
    Write-Host "Card $cardNumber is currently assigned to $assignedUser. Removing..."
    
    # Build params XML to remove card from existing user
    $removeParams = @"
    <param><value><string>$authToken</string></value></param>
    <param><value><string>$assignedUser</string></value></param>
    <param>
      <value>
        <array>
          <data>
            <value>
              <array>
                <data>
                  <value><string>primary-card-number</string></value>
                  <value><string></string></value>
                </data>
              </array>
            </value>
          </data>
        </array>
      </value>
    </param>
"@

    $removeResponse = Call-PaperCutApi 'api.setUserProperties' $removeParams
    Write-Host "Removed card from $assignedUser."
}

# Build params XML to assign card to target user
$assignParams = @"
    <param><value><string>$authToken</string></value></param>
    <param><value><string>$targetUser</string></value></param>
    <param>
      <value>
        <array>
          <data>
            <value>
              <array>
                <data>
                  <value><string>primary-card-number</string></value>
                  <value><string>$cardNumber</string></value>
                </data>
              </array>
            </value>
          </data>
        </array>
      </value>
    </param>
"@

$assignResponse = Call-PaperCutApi 'api.setUserProperties' $assignParams
Write-Host "Assigned card $cardNumber to $targetUser."
Write-Host "`nPaperCut Response:`n$assignResponse"
