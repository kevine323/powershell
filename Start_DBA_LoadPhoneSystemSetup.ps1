# Create and open a database connection
$sqlConnection = new-object System.Data.SqlClient.SqlConnection "server=SQLDW\Warehouse;database=msdb;Integrated Security=sspi"
$sqlConnection.Open()
 
#Create a command object
$sqlCommand = $sqlConnection.CreateCommand()
$sqlCommand.CommandText = "EXEC dbo.sp_start_job N'DBA_LoadPhoneSystemSetup'"
 
#Execute the Command
$sqlCommand.ExecuteReader()
 
# Close the database connection
$sqlConnection.Close()
