[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");

$Servers = Get-Content 'C:\TEST\Servers.txt';
ForEach ($Server in $Servers) {
$Results = Get-WMIObject -query "SELECT StatusCode FROM Win32_PingStatus WHERE Address = '$Server'"
$Responds = $false
    ForEach ($Result in $Results) {
        If ($Result.statuscode -eq 0) {
            $Responds = $true
            BREAK
        }
    }
    If ($Responds) {
        $srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server $Server
        
        If (!(Test-Path -path \\ntsrv\I_IS_PRIMARY\Tech_Services\SQLBackup_Test\$Server)) {
            New-Item \\ntsrv\I_IS_PRIMARY\Tech_Services\SQLBackup_Test\$Server\ -type directory
        }
        
        "sp_configure 'show advanced options',1
        RECONFIGURE
        GO
        sp_configure 'Database Mail XPs',1
        RECONFIGURE 
        GO" | Out-File \\ntsrv\I_IS_PRIMARY\Tech_Services\SQLBackup_Test\$Server\Test.txt
        
        $srv.Mail.Script() | Out-File \\ntsrv\I_IS_PRIMARY\Tech_Services\SQLBackup_Test\$Server\Test.txt -append   
        Write-Output "$Server Responds"            
    } Else {
        Write-Output "$Server Not Responding"
    }
}