[system.Reflection.Assembly]::LoadWithPartialName("Microsoft.SQLServer.Smo")

$SourceServer = New-Object Microsoft.SqlServer.Management.Smo.Server 'SQLAnalytics-T'

$DestServer = New-Object Microsoft.SqlServer.Management.Smo.Server 'SQLDBA\SQL2014'

$SingleDBOnly = "Y"
$SingleDB = "MF_Master"

[string]$DestData = $DestServer.DefaultFile
[string]$DestLog  = $DestServer.DefaultLog

$DestConn = $DestServer.ConnectionContext

foreach($Database in $SourceServer.Databases)
{
    "Processing database $($Database.Name):"

    $CMD = "
    SELECT TOP 1 
        bs.Server_Name,
        db.name AS DBName,
        bs.backup_finish_date,
        mf.physical_device_name
    FROM sys.databases db 
    LEFT OUTER JOIN [msdb].[dbo].[backupset] bs 
        ON  bs.database_name = db.name 
        AND bs.type = 'D' 
    JOIN msdb.dbo.backupmediaset ms
      on ms.media_set_id = bs.media_set_id
    JOIN msdb.dbo.backupmediafamily mf
      on mf.media_set_id = ms.media_set_id 
    WHERE db.name = '$($Database.Name)'
    AND mf.physical_device_name LIKE '\\%'
    and db.state = 0
    ORDER BY bs.backup_finish_date desc" 

    $Backups = ($SourceServer.ConnectionContext.ExecuteWithResults($CMD)).Tables[0]
  
    $DestConn.StatementTimeout = 0

    foreach($Backup in $Backups)
    {
        $CMD = "RESTORE FILELISTONLY FROM DISK = '$($Backup.physical_device_name)'"
    
        $DBFiles = ($DestConn.ExecuteWithResults($CMD)).Tables[0]
    
        $CMD = "
            RESTORE DATABASE [$($Backup.DBName)] 
            FROM  DISK = N'$($Backup.physical_device_name)' 
            WITH  FILE = 1,  
            NOUNLOAD,  
            STATS = 10"

        foreach($File in $DBFiles)
        {
            $LogicalName  = $File.LogicalName
            $PhysicalName = $File.PhysicalName
            $FileType     = $File.Type
  
            if($FileType = 'D')
            { 
                $FilePath = "$($DestData)$($PhysicalName.Split('\')[-1])" 
            } else { 
                $FilePath = "$($DestLog)$($PhysicalName.Split('\')[-1])" 
            }
            $CMD += "`r,MOVE N'$LogicalName' TO N'$FilePath'"

        }
        
        if (($SingleDBOnly -eq "Y") -and ($CMD.Contains($SingleDB)))
          {
            $CMD
            $DestConn.ExecuteNonQuery($CMD)
          }
        elseif ($SingleDBOnly -eq "N")
          {
            $CMD
            $DestConn.ExecuteNonQuery($CMD)
          }
           
          
        #$DestConn.ExecuteNonQuery($CMD)        
        #$$DestConn.ExecuteNonQuery('DBCC FREEPROCCACHE')
        #$DestConn.ExecuteNonQuery('DBCC FREESYSTEMCACHE(''All'')')
        #$DestConn.ExecuteNonQuery("DBCC CheckDB('DBCC_Check_$($Database.Name)')")
        #$DestConn.ExecuteNonQuery("DROP DATABASE [DBCC_Check_$($Database.Name)]")
    }
}