."\\USA.com\USERS\Van Buren\wkeckha\My Documents\powershell\Install-SSRSRDL.ps1"
$ReportServer = "http://cognosgate-t/Reportserver"
$ReportFolder = "Reports"
$ReportName = "MyReport"
Install-SSRSRDL "http://cognosgate-t/ReportServer/ReportService2005.asmx?WSDL" `
"C:\development\USATruck\RELEASE\Source\USATruck.SSRS\USATruck.SSRS.Dashboard.KPI\KPI Trend Comparison.rdl" -force `
-reportFolder $ReportFolder `
-reportName $ReportName

#"$ReportServer/$ReportFolder/$ReportName.rdl"

#open IE
$ie = New-Object -ComObject InternetExplorer.Application
$ie.Navigate("$ReportServer/$ReportFolder")
$ie.Visible = $true