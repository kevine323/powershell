# Author:  Tim Chapman, MSFT
# Date:  8/16/2012
# This script is provided "AS IS" with no warranties, and confers no rights.


Function ProcessDBCCMemoryStatus
{
    Param
    (
        [String] $FileLocation, 
        [String] $SQLServer, 
        [String] $DBName
    )

        #Values for local testing
        #$FileLocation = "C:\Powershell Scripts\dbcc.txt"
        #$SQLServer = ".\sql2008r2"
        #$DBName = "AdventureWorks2008R2"
                
        if($FileLocation -eq "")
        {
            #load from instance into array.  Must use sqlcmd here as invoke-sqlcmd doesn't format the output properly
            $DBCCMemoryStatus = @(sqlcmd.exe -S $SQLServer -E -d "master" -Q "DBCC MEMORYSTATUS" )
        }
        else
        {
            #otherwise get dbcc memorystatus from file
            $DBCCMemoryStatus = get-content $FileLocation
        }

        $DBConnection = new-object system.data.SqlClient.SQLConnection("Data Source=$SQLServer;
        Integrated Security=SSPI;Initial Catalog=$DBName");
        $DBConnection.open()
        $Command = new-object system.data.sqlclient.sqlcommand;
        $Command.Connection = $DBConnection
        $Command.CommandText = "IF OBJECT_ID('DBCCMemoryStatus') IS NOT NULL DROP TABLE DBCCMemoryStatus"
        $Command.ExecuteNonQuery() | out-null
        $Command.CommandText = "CREATE TABLE DBCCMemoryStatus(IDCol INT IDENTITY(1,1), MemObjType VARCHAR(1200), 
        MemObjName VARCHAR(1200), MemObjValue BIGINT, ValueType VARCHAR(20))"
        $Command.ExecuteNonQuery() | out-null

        for ($i = 0; $i -lt $DBCCMemoryStatus.length; $i++)
        {

            if ([regex]::ismatch($DBCCMemoryStatus[$i+1],"-----------------------"))
            {
                [int] $pivot = $DBCCMemoryStatus[$i+1].IndexOf(" ")
            }


            if (     
                    ($DBCCMemoryStatus[$i].trim() -ne "") -and 
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"-----------------------")) -and 
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"affected")) -and
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"Start time:")) -and
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"MEM_SNAPSHOT_INTERVAL")) -and
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"Sample interval:")) -and
                    (![regex]::ismatch($DBCCMemoryStatus[$i],"DBCC"))
                    
                )
            {
                if ([regex]::ismatch($DBCCMemoryStatus[$i+1],"-----------------------"))
                {
                    $valtype = $DBCCMemoryStatus[$i].substring($pivot + 1, ($DBCCMemoryStatus[$i].Length - $pivot -1))
                    $memtype = ($DBCCMemoryStatus[$i]).replace($valtype,"")

                }
        
                if (![regex]::ismatch($DBCCMemoryStatus[$i+1],"-----------------------"))
                {
                    $MemObjType = $memtype
                    $MemObjName = $DBCCMemoryStatus[$i].substring(0, $pivot)
                    [int64]$MemObjValue = $DBCCMemoryStatus[$i].substring($pivot + 1, 
                        ($DBCCMemoryStatus[$i].Length - $pivot -1))        
                    $Command.CommandText = "INSERT INTO DBCCMemoryStatus (MemObjType, MemObjName, MemObjValue, ValueType) 
                    VALUES ('$MemObjType','$MemObjName', '$MemObjValue', '$valtype')"
                    
                    $Command.ExecuteNonQuery() | out-null
                }
            }
        }
        $DBConnection.Close();
}



# example
#ProcessDBCCMemoryStatus -FileLocation "" -SQLServer "timchap-msft\sql2012" -DBName "AdventureWorks2012"
