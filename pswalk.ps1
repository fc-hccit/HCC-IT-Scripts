# To reduce the amount of red on the screen.
#$ErrorActionPreference = "silentlycontinue"

# Load a SNMP thingy via printer COM Object (yes, printers!!)
$SNMP = New-Object -ComObject olePrn.OleSNMP

# some variables used
$comstr = 
$hosts = 


## --= Info on above vars =-- ##
# $comstr -- comstr == the community string to test
# $hosts -- host,oid -- .1.3.6.1.2.1.1.1.0 == system description and typically always available
##

# just incase this has been run after some failed attempts...
$error.clear()

foreach ($h in $hosts){
write-host "Testing $($h.host)"
if (Test-Connection $h.host -count 1 -ea 0) {
for ($i = 0;$i -lt ($comstr | measure).count;$i++){
#establish SNMP connection. Unfortunately this does not error :(
$snmp.open($h.host,$comstr[$i].comstr,2,1000)

try {
$snmp.get($h.oid) | out-null
}catch{
$snmp.close()
if ($i -eq ($comstr | measure).count-1) {
# the if () above is checking if all comstr's have been used. If so ends for loop and updates $result
$result += New-Object PsObject -Property ([ordered]@{ Host = $h.host ; Com_str = "No working Community String identified or possible OID error"})
$error.clear()
break
}
} #catch

# If there is an error.. do nothing
if (!$error){
# if there is no error, it worked. Exit the for loop. no need to test further. Record it..
$result += New-Object PsObject -Property ([ordered]@{ Host = $h.host ; Com_str = $comstr[$i].comstr})
break
}
$error.clear()
} #for
}else{
$result += New-Object PsObject -Property ([ordered]@{ Host = $h.host ; Com_str = "Host not found or not responding"})
}
#closes successful connections and clears errors.
$snmp.close()
$error.clear()

}

$result


$snmp.gettree('.1.3.6.1.2.1.1.1')
