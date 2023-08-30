(Get-WmiObject -computer Applications2 Win32_Service -Filter "Name='USATruck.WindowsServices.OperationsMetrics'").InvokeMethod("StopService",$null)
(Get-WmiObject -computer Applications2 Win32_Service -Filter "Name='USATruck.WindowsServices.OperationsMetrics'").InvokeMethod("StartService",$null)

Write-Host "Press any key to continue ..."

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")



