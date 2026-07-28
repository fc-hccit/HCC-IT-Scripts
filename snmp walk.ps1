
class SNMPResult {
    [string]$Oid
    [string]$Value
    SNMPResult([string]$Oid,[string]$Value) {
        $this.Oid = $Oid
        $this.Value = $Value
    }
}

function Init-Snmp([string]$Hostname, [string]$Community = "public") {
    $comSnmp = New-Object -ComObject olePrn.OleSNMP
    $comSnmp.Open($Hostname, $Community)
    return $comSnmp
}

function Prepare-Oid([string]$Oid) {
    if( -not $Oid.StartsWith(".") ) {
        $Oid = ".$Oid"
    }
    return $Oid.Trim()
}

function Get-SnmpWalk() {
    [cmdletbinding()] Param(
        [Parameter(Position=0, Mandatory=$true)][string]$Hostname,
        [Parameter(Position=1, Mandatory=$true)][string]$Oid,
        [Parameter(Position=2, Mandatory=$false)][string]$Community = "public"
    )
    try { 
        $comSnmp = Init-Snmp -Hostname $Hostname -Community $Community
        $result = $comSnmp.GetTree((Prepare-Oid -Oid $Oid))
        $comSnmp.Close()
    }
    catch {
        $result = @()
    }
    for($a = 0; $a -lt $result.Count / 2; $a++) {
        [SNMPResult]::new(".$($comSnmp.OIDFromString($($result[0, $a])) -join ".")", "$($result[1, $a])")
    }
}



function Get-SnmpWalkValue() {
    [cmdletbinding()] Param(
        [Parameter(Position=0, Mandatory=$true)][string]$Hostname,
        [Parameter(Position=1, Mandatory=$true)][string]$Oid,
        [Parameter(Position=2, Mandatory=$false)][string]$Community = "public"
    )
    Get-SNMPWalk -Hostname $Hostname -Oid $Oid -Community $Community | % {
        if( $_ -ne $null ) {
            $_.Value
        }
        else {
            ""
        }
    }
}

Get-SnmpWalk


function Get-Snmp() {
    [cmdletbinding()] Param(
        [Parameter(Position=0, Mandatory=$true)][string]$Hostname,
        [Parameter(Position=1, Mandatory=$true)][string]$Oid,
        [Parameter(Position=2, Mandatory=$false)][string]$Community = "public"
    )
    try {
        $comSnmp = Init-Snmp -Hostname $Hostname -Community $Community
        $result = $comSnmp.Get((Prepare-Oid -Oid $Oid))
        $comSnmp.Close()
    }
    catch {
        $result = ""
    }
    [SNMPResult]::new($Oid, $result)
}



function Get-SnmpValue() {
    [cmdletbinding()] Param(
        [Parameter(Position=0, Mandatory=$true)][string]$Hostname,
        [Parameter(Position=1, Mandatory=$true)][string]$Oid,
        [Parameter(Position=2, Mandatory=$false)][string]$Community = "public"
    )
    $result = Get-SNMP -Hostname $Hostname -Oid $Oid -Community $Community
    if( ($result -ne $null) -and ($result.Value -ne $null) ) {
        return $result.Value
    }
    return ""
}
