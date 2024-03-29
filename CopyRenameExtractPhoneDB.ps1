################################################################################
#Setup Info
#Set Database Directory -- This Is Where My SSIS Package Pulls From
$DbDirectory = "\\ntsrv\t_datacent\TECH_SERVICES\DBA\PhoneSystem\"

#Get Node Backup Directories -- The Phone System Dumps It's Backups Here
$N1BkDirectory = "\\ntsrv\t_datacent\NETWORK\Communications Admin\Backups\N1\*.axx"
$N2BkDirectory = "\\ntsrv\t_datacent\NETWORK\Communications Admin\Backups\N2\*.axx"

#End Setup Info
################################################################################


#Get The Last Backup
$N1Backup = dir $N1BkDirectory | sort -property lastwritetime | select -last 1 
$N2Backup = dir $N2BkDirectory | sort -property lastwritetime | select -last 1 

#Copy Files To Database Directory and rename to zip
Copy-Item $N1Backup ("$DbDirectory" + "Node1.zip")
Copy-Item $N2Backup ("$DbDirectory" + "Node2.zip")

#unzip application
$sh = new-object -com shell.application

#Unzip and Copy Remote1.mdb from Node1.zip
$zipfolder = $sh.namespace("$DbDirectory" + "Node1.zip") 
$item = $zipfolder.parsename("Intertel\Sessions\remote1.mdb")      # the item in the zip
$targetfolder = $sh.namespace("$DbDirectory")       # where the item is to go
$targetfolder.copyhere($item,0x10)

#Unzip and Copy Remote2.mdb from Node2.zip
$zipfolder = $sh.namespace("$DbDirectory" + "Node2.zip") 
$item = $zipfolder.parsename("Intertel\Sessions\remote2.mdb")      # the item in the zip
$targetfolder = $sh.namespace("$DbDirectory")       # where the item is to go
$targetfolder.copyhere($item,0x10)