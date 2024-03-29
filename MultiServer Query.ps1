<#
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Import-Module activedirectory
#>
$query = "Select Getdate()"

$ServerName = "SQLUsaTools"  #SQL Server Commands Will Be Ran Against
$cn = new-object System.Data.SqlClient.SqlConnection "server=$ServerName;Integrated Security=sspi; Connection Timeout=5" #create a Connection to the SQL Server database

$command = "SELECT [Server] FROM [SQL_Overview].[dbo].[ServerList]"
$DataSet =  new-object "System.Data.DataSet"

$dataAdapter = new-object "System.Data.SqlClient.SqlDataAdapter" ($command, $cn)
$dataAdapter.SelectCommand.CommandTimeout = 5
$dataAdapter.Fill($DataSet) | Out-Null

$dataTable = new-object "System.Data.DataTable"
$dataTable = ($DataSet.Tables[0])

clear-host

foreach($row in $datatable.rows)
{
    write-host "Checking " $row["server"]
    Invoke-Sqlcmd -ConnectionTimeout 5 -Query $query -ServerInstance ($row["server"])
}