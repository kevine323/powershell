<#
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Import-Module activedirectory
Import-Module System.Configuration
#>
$SourceServer = "SQLAnalytics"
$SourceInstance = "default"
$SourceDatabase = "MF_Master"
$SourceTable = "Rev_Exp_History"
$Schema = "dbo"
$SourceCommand = "Select * From $SourceDatabase.dbo.$SourceTable"

$TruncateDestTable = "Y"
$DropAndCreateTable = "N"

$DestServer = "SQLAnalytics-T"
$DestInstance = "default"
$DestDatabase = "MF_Master"
$DestTable = "Rev_Exp_History"

$SourceConnection = new-object System.Data.SqlClient.SqlConnection "server=$SourceServer;Integrated Security=sspi; Connection Timeout=5" #create a Connection to the SQL Server database
$SourceDataSet =  new-object "System.Data.DataSet"

$DestConnection = new-object System.Data.SqlClient.SqlConnection "server=$DestServer;Integrated Security=sspi; Initial Catalog=$DestDatabase" #create a Connection to the SQL Server database

$SourceDataAdapter = new-object "System.Data.SqlClient.SqlDataAdapter" ($SourceCommand, $SourceConnection)
$SourceDataAdapter.SelectCommand.CommandTimeout = 5
$SourceDataAdapter.Fill($SourceDataSet) | Out-Null
$SourceDataTable = ($SourceDataSet.Tables[0])

$DestConnection.Open()

If ($DropAndCreateTable -eq "Y") #Drop table on dest side (if exists) and create new one
{
    $Table = Get-ChildItem SQLSERVER:SQL\$SourceServer\default\databases\$SourceDatabase\Tables | Where-object {$_.schema -eq$Schema-and$_.name -like$SourceTable}
    $DropSQL = "IF OBJECT_ID(N'$Schema.$DestTable', N'U') IS NOT NULL DROP TABLE $Schema.$DestTable;"
    $CreateSQL  = $Table.Script()
    <#
    $DropSQL
    $CreateSQL
    #>
    Invoke-SQLCmd -Query $DropSQL -ServerInstance "$DestServer"
    
    foreach($string in $CreateSQL)
     {Invoke-SQLCmd -Query $string -ServerInstance "$DestServer"}
    
}    

if($TruncateDestTable -eq "Y")
{ 
    $TruncateSql = "TRUNCATE TABLE " + $DestTable
    Sqlcmd -S $DestServer -d $DestDatabase -Q $TruncateSql
}

#Remove Computed Columns
$cols = @(Get-ChildItem SQLSERVER:SQL\$SourceServer\default\databases\$SourceDatabase\Tables\$Schema.$SourceTable\Columns | Where-Object {$_.Computed -NE $TRUE}| Sort-Object -Property ID | 
          ForEach-Object{"[" + $_.Name + "]"})
$colnames = $cols -join ","

Try
{
    $BulkCopy = new-object ("System.Data.SqlClient.SqlBulkCopy") $DestConnection 
    
    Foreach($col in $cols)
    {
        [Void]$BulkCopy.ColumnMappings.Add($col, $col)
    }
    
    #$BulkCopy.KeepIdentity = $TRUE
    $BulkCopy.DestinationTableName = $DestTable
    $BulkCopy.BatchSize = 10000; 
       
    $BulkCopy.NotifyAfter = 10    
    $objectEvent= Register-ObjectEvent $BulkCopy SqlRowsCopied -Action {write-host "Copied $($eventArgs.RowsCopied) rows "}
    $BulkCopy.WriteToServer($SourceDataTable)   
    
     
}
Catch [System.Exception]
{
    $ex = $_.Exception
    Write-Host $ex.Message
}
  Finally
{       
    $SourceConnection.Close()
    $SourceConnection.Dispose()
    $DestConnection.Close()
    $DestConnection.Dispose()
    $BulkCopy.Close()
}
