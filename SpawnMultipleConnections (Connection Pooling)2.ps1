# Create ADO connection and recordset objects	
$adoOpenStatic = 0
$adoLockOptimistic = 3
$adoConnection = New-Object -comobject ADODB.Connection
$adoRecordset = New-Object -comobject ADODB.Recordset

#Connection String
$adoConnection.Open("Provider=SQLOLEDB;Data Source=NTSRVTEST11;Initial Catalog=MF_Master;Integrated Security=SSPI")
#Statement 
$query = "Select Top 1000 * from Frt_Bill_Master"

#iterator
$X=0

do
{
$adoRecordset.Open($query, $adoConnection, $adoOpenStatic, $adoLockOptimistic)
$adoRecordset.MoveFirst()
#Start-Sleep -m 10
"$X"
$x=$x+1
$adoRecordset.Close()
} until ($x -eq 1000)

$adoConnection.Close()


  