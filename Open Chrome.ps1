while ($true){

if(!(get-Process -name chrome)){

$url1 = "https://www.hopecc.sa.edu.au/"
$url2 = "https://www.2goschools.com"
$url3 = "https://www.google.com/intl/en-GB/gmail/about/"
$url4 = "https://www.schoolinterviews.com.au/"
 
start-process chrome.exe -WindowStyle Maximized -ArgumentList " --incognito $url4 $url1 $url2 $url3 "
}
}