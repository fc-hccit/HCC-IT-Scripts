$Computers = "A4640KF02164","ACERSWITCH-TIM","A4610RP02219","A4640JD2280","A4610JG02215","A4610AR02217","A4610KG00124","A4610MB02210","A4610TH02218"

ForEach ($Computer in $Computers) 

{

if (-not (Test-Connection -count 1 -comp $Computer -quiet))
{

Write-host "$computer is down" -ForegroundColor Red

} 

Else 

{

Copy-Item -Path "C:\Engineer\PCSchoolUpdate\*" -Destination "\\$Computer\c$\PCSLaunch\Programs" -force -PassThru

}
}