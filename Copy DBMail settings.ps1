[void][reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo");

#Set the server to script from
$ServerName = "NTSRVTEST11";

#Get a server object which corresponds to the default instance
$srv = New-Object -TypeName Microsoft.SqlServer.Management.SMO.Server $ServerName

#Script Database Mail configuration from the server
$srv.Mail.Script();
