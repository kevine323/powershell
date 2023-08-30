CLS
Set-StrictMode -Version 2
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")
[Void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")
$Conn = new-object Microsoft.SqlServer.Management.Common.ServerConnection
$Conn.applicationName = "PowerShell GetSQLDBInfo (using SMO)"

#Set the parameters for the environment
$Conn.ServerInstance="SQLDYN\Dynamics"
$Conn.LoginSecure = $True                  #Set to true connect using Windows Authentication
#$Conn.Login = "sa"                          #Do not apply if you use Windows Authentication
#$Conn.Password = "SAPassword"               #Do not apply if you use Windows Authentication

#Connect to the SQL Server and get the databases
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $conn
$dbs = $srv.Databases



#Process All Databases
  foreach ($db in $dbs)
    {    
    if ($db.Status -like "Normal")
    {
    foreach ($dbfile in $db.FileGroups.files) 
      {
       $dbfilesize = [math]::floor($dbfile.Size/1024)           #Convert to MB
       if ($dbfile.growthtype -eq "KB") 
            {
            $dbfilegrowth=[math]::floor($dbfile.growth/1024)
            write-host $db.name, $dbfile.filename, "Size:"$dbfilesize" MB", "Growth:"$dbfilegrowth" MB" 
            } 
       else {$dbfilegrowth=$dbfile.growth                    
            write-host $db.name, $dbfile.filename, "Size:"$dbfilesize" MB", "Growth:"$dbfilegrowth, $dbfile.growthtype 
            }
      }
    #Process all log files used by the database 
    foreach ($dblogfile in $db.logfiles) {
       $dblogfilesize = [math]::floor($dblogfile.size/1024)   #Convert to MB
       if ($dblogfile.growthtype -eq "KB") 
            {
            $dblogfilegrowth=[math]::floor($dblogfile.growth/1024)
            write-host $db.name, $dblogfile.filename, "Size:"$dblogfilesize" MB", "Growth:"$dblogfilegrowth" MB" 
            } 
       else 
            {
            $dblogfilegrowth=$dblogfile.growth
            write-host $db.name, $dblogfile.filename, "Size:"$dblogfilesize" MB", "Growth:"$dblogfilegrowth, $dblogfile.growthtype 
            }
            
      }
    }
    }
#disconnect
$srv.ConnectionContext.Disconnect()