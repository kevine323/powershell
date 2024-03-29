set-location c:\development
$Comment = """142925"""

$CommandLocation = "C:\Program Files (x86)\Microsoft Visual Studio 10.0\Common7\IDE\TF.exe "
$GetDevCommand = " get $/USATruck/DEV/AppDev/Source/USATruck.SSRS /recursive /force "
$GetMainCommand = " get $/USATruck/MAIN/Source/USATruck.SSRS /recursive /force "
$GetReleaseCommand = " get $/USATruck/Release/Source/USATruck.SSRS /recursive /force "

$MergeToMain = " merge $/USATruck/DEV/AppDev/Source/USATruck.SSRS $/USATruck/MAIN/Source/USATruck.SSRS /recursive  /version:T"
$CheckinToMain = " checkin /comment:$comment /recursive /noprompt ""c:\development\USATruck\MAIN\Source\USATruck.SSRS"""

$MergeToRelease = " merge $/USATruck/MAIN/Source/USATruck.SSRS $/USATruck/Release/Source/USATruck.SSRS /recursive  /version:T"
$CheckinToRelease = " checkin /comment:$comment /recursive /noprompt ""c:\development\USATruck\Release\Source\USATruck.SSRS"""

##Get Lastest Files From Sources Control
Start-Process "$CommandLocation" "$GetDevCommand" -wait -RedirectStandardOutput c:\temp\Get-TFS.txt
Start-Process "$CommandLocation" "$GetMainCommand" -wait -RedirectStandardOutput c:\temp\Get-TFS.txt
Start-Process "$CommandLocation" "$GetReleaseCommand" -wait -RedirectStandardOutput c:\temp\Get-TFS.txt

##Merge and Checkin to Main
Start-Process "$CommandLocation" "$MergeToMain" -nonewwindow -wait -RedirectStandardOutput c:\temp\MergePreProd-TFS.txt
Start-Process "$CommandLocation" "$CheckinToMain" -nonewwindow -wait -RedirectStandardOutput c:\temp\CheckinPreProd-TFS.txt

##Merge and Checkin to Release
Start-Process "$CommandLocation" "$MergeToRelease" -nonewwindow -wait -RedirectStandardOutput c:\temp\MergeProd-TFS.txt
Start-Process "$CommandLocation" "$CheckinToRelease" -nonewwindow -wait -RedirectStandardOutput c:\temp\CheckinProd-TFS.txt

<#
$CommandLocation 
$GetCommand
$CommandLocation 
$MergeToMain
$CommandLocation 
$CheckinToMain
$CommandLocation 
$MergeToRelease
$CommandLocation 
$CheckinToRelease
#>