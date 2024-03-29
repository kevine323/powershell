<#
Param(
  [Parameter(
  Mandatory = $true,
  ParameterSetName = '',
  ValueFromPipeline = $true)]
  [string]$Query
  )
#>
$MySQLAdminUserName = 'USA_Reader'
$MySQLAdminPassword = 'readme2012'
$MySQLDatabase = 'OORETA'
$MySQLHost = '10.10.21.100'
$ConnectionString = "server=" + $MySQLHost + ";port=3306;uid=" + $MySQLAdminUserName + ";pwd=" + $MySQLAdminPassword + ";database="+$MySQLDatabase
$ReportDate = [DateTime]::Now.AddDays(-5)
$ReportDate.ToString("yyyyMMdd")

Try {
  [void][System.Reflection.Assembly]::LoadWithPartialName("MySql.Data")
  $Connection = New-Object MySql.Data.MySqlClient.MySqlConnection
  $Connection.ConnectionString = $ConnectionString
  $Connection.Open()
  $Query = 'Delete From load_Report where report_name = ''' + $ReportDate.ToString("yyyyMMdd") +''''  
  
  
  $Command = New-Object MySql.Data.MySqlClient.MySqlCommand($Query, $Connection)
  $Command.ExecuteNonQuery()
  
  #$DataAdapter = New-Object MySql.Data.MySqlClient.MySqlDataAdapter($Command)
  #$DataSet = New-Object System.Data.DataSet
  #$RecordCount = $dataAdapter.Fill($dataSet, "data")
  #$DataSet.Tables[0]
  
  }

Catch {
  Write-Host "ERROR : Unable to run query : $query `n$Error[0]"
 }

Finally {
  $Connection.Close()
  }
  
 