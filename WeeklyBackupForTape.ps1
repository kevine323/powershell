$weeklybackupdir = '\\ddbackup\ddsql\SQLWeeklyBackup'
$directory = '\\ddbackup\ddsql\SQLBackup_Prod'
$files = gci $directory -recurse |
where {$_.psiscontainer -and $_.FullName -notlike "*\archive*"} |
foreach {
    get-childitem $_.fullname -Filter *.bak| 
    sort creationtime | 
    select -expand fullname -last 1
    }

foreach ($name in $files)
{
$Date = Get-Date
Write-Host 'Starting ' $name ' at ' $Date
Copy-Item $name $weeklybackupdir
$Date = Get-Date
Write-Host 'Finished ' $name ' at ' $Date
}



