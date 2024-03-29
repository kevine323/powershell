<###########################################
Author  : Kevin Eckart
Date    : 9/22/2014
Purpose : Automatically Restore Tlogs outside of Tlog Shipping and log actions. Will restore full backup if needed

Sections
1: Create Objects
2: Restore Full Backup if needed
3. Restore Tlog Backups in order
###########################################>

<#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Section 1
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#>

<###########################################
Vars to be set before execution
###########################################>
$Database = 'EVVSPublicFolderStore01_5'  #NAME OF DATABASE TO BE RESTORED
$Server = "SQLDBA\SQL2014" #SERVER OBJECT WHERE THE DATABASE WILL BE RESTORED
$LogDirectory = "\\vbdbdd670\DDSQL\SQLBackup_Prod\EVSQL\$Database\Log" #LOCATION OF BACKUPS TO BE RESTORED
$FullDirectory = "\\vbdbdd670\DDSQL\SQLBackup_Prod\EVSQL\$Database\FULL" #LOCATION OF BACKUPS TO BE RESTORED
$RestoreLastFullBackup = 'Y'
<###########################################
End vars to be set before execution
###########################################>

<###########################################
Create Objects
###########################################>
$SQLSvr = New-Object -TypeName  Microsoft.SQLServer.Management.Smo.Server($Server) 
$Restore = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Restore
$DeviceType = [Microsoft.SqlServer.Management.Smo.DeviceType]::File
<###########################################
End Create Objects
###########################################>

<#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Section 2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#>

<###########################################
Restore Last Full Backup?
###########################################>
if($RestoreLastFullBackup -eq 'Y')
{
    $Files = Get-ChildItem -Path $FullDirectory -Filter *.bak |  sort creationtime | select -last 1
    Foreach ($File in $Files) #Should only be 1
    {
        $FileDate = $File.CreationTime     
        $FilePath = $file.FullName      
        $RestoreDevice = New-Object -TypeName Microsoft.SQLServer.Management.Smo.BackupDeviceItem($file.FullName,$devicetype) 
        $Restore.Devices.Add($RestoreDevice) | out-null
    
        $info = $Restore.ReadBackupHeader($sqlsvr) 
    
        $Restore.Database = $Database
        $Restore.FileNumber = 1
        $Restore.NoRecovery = $True 
        $Restore.ReplaceDatabase = $True           
            
        Try
        {
            $restore.SqlRestore($SQLSvr)
            $FirstLSN = $info.Rows[0]["FirstLSN"]
            $LastLSN =  $info.Rows[0]["LastLSN"]
            $query = "Insert Into DBA.dbo.TLogRestores (DBName,BackupDate,FirstLSN,LastLSN,RestoreFile,RestoreTime,Outcome) VALUES  ( '$Database','$FileDate',$FirstLSN, $LastLSN, '$FilePath', getdate(), 'SUCCESS') "
            Invoke-Sqlcmd -Query $query -ServerInstance ($Server)    
            write-output "$File succedded"
        }
        Catch [system.exception]
        {
            $query = "Insert Into DBA.dbo.TLogRestores (DBName,BackupDate,RestoreFile,RestoreTime,Outcome) VALUES  ( '$Database','$FileDate', '$File.FullName', getdate(), $_.Exception.Message) "
            Invoke-Sqlcmd -Query $query -ServerInstance ($Server)    
            write-output "$File failed"
        }
        Finally
        {
            $Restore.Devices.Remove($restoredevice) | out-null  
        }
    }     
}

<#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Section 3
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#>

<###########################################
Restore TLogs
###########################################>

<###########################################
Get the date of the last transaction log restored
###########################################>
$BackupDate = $null
$BackupDate = (Invoke-Sqlcmd -Query "SELECT Max(BackupDate) BackupDate FROM DBA.dbo.TLogRestores WHERE DBName = '$Database'" -ServerInstance ($Server)).BackupDate

<###########################################
If the backup date is null, write error to log
###########################################>
if ($BackupDate -eq [DBNull]::Value)
{
        $query = "Insert Into DBA.dbo.TLogRestores (DBName,RestoreTime,Outcome) VALUES  ( '$Database', getdate(), 'UNKNOWN LAST BACKUP TIME. PLEASE INSERT DATE FOR THE LAST TLOG OR FULL BACKUP RESTORED FOR THIS DB') "
        Invoke-Sqlcmd -Query $query -ServerInstance ($Server)    
        write-output "Retrieve BackupDate failed"
        exit       
}

$Files = Get-ChildItem -Path $LogDirectory -Filter *.trn |  Where-Object { $_.CreationTime -ge $BackupDate} | sort creationtime
Foreach ($File in $Files)
    {
        $FileDate = $File.CreationTime  
        $FilePath = $file.FullName        
        $RestoreDevice = New-Object -TypeName Microsoft.SQLServer.Management.Smo.BackupDeviceItem($file.FullName,$devicetype) 
        $Restore.Devices.Add($RestoreDevice) | out-null
        
        $info = $Restore.ReadBackupHeader($sqlsvr) 
        
        $Restore.Database = $Database
        $Restore.FileNumber = 1
        $Restore.NoRecovery = $True    
        
        Try
        {
            $restore.SqlRestore($SQLSvr)
            $FirstLSN = $info.Rows[0]["FirstLSN"]
            $LastLSN =  $info.Rows[0]["LastLSN"]
            $query = "Insert Into DBA.dbo.TLogRestores (DBName,BackupDate,FirstLSN,LastLSN,RestoreFile,RestoreTime,Outcome) VALUES  ( '$Database','$FileDate',$FirstLSN, $LastLSN, '$FilePath', getdate(), 'SUCCESS') "
            #$query
            Invoke-Sqlcmd -Query $query -ServerInstance ($Server)    
            write-output "$File succedded"
        }
        Catch [system.exception]
        {
            $query = "Insert Into DBA.dbo.TLogRestores (DBName,BackupDate,RestoreFile,RestoreTime,Outcome) VALUES  ( '$Database','$FileDate', '$FilePath', getdate(), $_.Exception.Message) "
            #$query
            Invoke-Sqlcmd -Query $query -ServerInstance ($Server)    
            write-output "$File failed"
        }
        Finally
        {
            $Restore.Devices.Remove($restoredevice) | out-null  
        }
      
    }
