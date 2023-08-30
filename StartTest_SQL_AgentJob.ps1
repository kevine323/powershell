#Vars for Server and JobName
$Server = "NTSRVTEST11"
$JobName = "Build_Hierarchy_Summary_Table"


#Create/Open Connection
$sqlConn = new-object System.Data.SqlClient.sqlConnection "server=$Server;database=msdb;Integrated Security=sspi"
$sqlConn.Open()
 
#Create Command Obj
$sqlCommand = $sqlConn.CreateCommand()
$sqlCommand.CommandText = "EXEC dbo.sp_start_job N'$JobName'"
 
#Exec Command
$sqlCommand.ExecuteReader()
 
#Close Conneection
$sqlConn.Close()
