$DB = "RYDER_SCOS"
$SourceInstance = "AZRVPTMWCSQL1"
$DestinationInstance1 ="AZRVPTMWCSQL2"
$DestinationInstance2 ="AZRVPTMWCSQL3"
$FullBackup = "\\AZRVPTMWCSQL1\backup\bkRYDER_SCOS_for_AG.bak"
$Tlog = "\\AZRVPTMWCSQL1\backup\bkRYDER_SCOS_for_AG.trn"
$AvailabilityGroup = "TMWcAAIProd"
#Restore-SqlDatabase -Database $DB -BackupFile $FullBackup -ServerInstance $DestinationInstance -KeepReplication


# Create database backup  
Backup-SqlDatabase -Database $DB -BackupFile $FullBackup -ServerInstance $SourceInstance  
# Create log backup  
Backup-SqlDatabase -Database $DB -BackupAction "Log" -BackupFile $Tlog -ServerInstance $SourceInstance  
# Restore database restore to Secondary 
Restore-SqlDatabase -Database $DB -BackupFile $FullBackup -NoRecovery -ServerInstance $DestinationInstance1  
# Restore log backup restore to Secondary  
Restore-SqlDatabase -Database $DB -BackupFile $Tlog -RestoreAction "Log" -NoRecovery –ServerInstance $DestinationInstance1  

#3rd instance
# Restore database restore to Secondary 
Restore-SqlDatabase -Database $DB -BackupFile $FullBackup -NoRecovery -ServerInstance $DestinationInstance2  
# Restore log backup restore to Secondary  
Restore-SqlDatabase -Database $DB -BackupFile $Tlog -RestoreAction "Log" -NoRecovery –ServerInstance $DestinationInstance2  

Add-DbaAgDatabase -SqlInstance $SourceInstance -AvailabilityGroup $AvailabilityGroup -Database $DB -SeedingMode Manual -Secondary $DestinationInstance1, $DestinationInstance2