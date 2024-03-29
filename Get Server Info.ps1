#find the top 10 largest tables (in rows) in a database
dir sqlserver:\sql\tp_w520\default\databases\adventureworks2012\tables | sort rowcount -desc | select name, rowcount -first 10;

#find out logins with sysadmin rights on mulitple servers (assume the default sql instance only)
'ServerA', 'ServerB', 'ServerC' | % { dir "sqlserver:\sql\$_\default\logins" }  | ? {$_.ismember('sysadmin')} | select Parent, Name;

#find user database sizes across multi servers (assuming default sql instances)
'ServerA', 'ServerB', 'ServerC' | % { dir sqlserver:\sql\$_\default\databases } |  select parent, name, size | ogv -Title "Database Size(MB)";

#check whether a specific login name is on which servers (assume default sql instances)
'ServerA', 'ServerB', 'ServerC' | % { dir sqlserver:\sql\$_\default\logins } | ? {$_.name -eq 'specific-loginname'} |  select Parent, Name;

#check whether there is any non-simple recovery database which has not a had a transaction log backup in the last 1 hour
'ServerA', 'ServerB', 'ServerC' | % {dir sqlserver:\sql\$_\default\databases} | ? {($_.RecoveryModel -ne 'Simple') -and ($_.lastlogbackupdate -lt (get-date).addhours(-1))} | select Parent, Name, LastLogbackupdate;

#find out the database user role membership 
dir sqlserver:\sql\tp_w520\default\databases\MyTestDB\users | % -Begin {$a=@()} -process { $a += New-Object PSObject -property @{User=$_; Role=$_.EnumRoles()} } -end {$a} | select User, Role;

#find the last execution status of all SQL Server Agent Jobs on a SQL Server instance
dir sqlserver:\sql\tp_w520\default\jobserver\jobs | % {$_.enumhistory()} | group  jobname | % {$_.group[0]} | select  Server,  JobName,  RunDate,  Message;

#find the current failed SQL Server Agent Jobs
dir sqlserver:\sql\tp_w520\default\jobserver\jobs | % {$_.enumhistory()} | group  jobname | % {$_.group[0]} | ? {$_.RunStatus -eq 0}  |  select Server, JobName, Rundate, Message;

#get the reason of last server shutdown/reboot (note: the local language should be English - US, otherwise, [Message] will not be displayed. This is a reported bug)
'ServerA', 'ServerB', 'ServerC' | % {Get-WinEvent -ComputerName $_ -filterhashtable @{logname='System'; id=1074; level=4} -MaxEvents 1 } | select Message, TimeCreated | format-list;

#check when the multiple machines were last rebooted
gwmi -class win32_OperatingSystem -Computer ServerA, ServerB, ServerC | select @{label='Server'; e={$_.PSComputerName}}, @{label='LastBootupTime'; e={$_.converttodatetime($_.lastBootupTime)}};
