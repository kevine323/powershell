#first we need to import SQLPS module
import-module SQLPS -DisableNameChecking;

# script out all foreign keys in T-SQL
dir sqlserver:\sql\NTSRVTEST11\default\databases\USATruck\tables | % {$_.foreignkeys } |  % {$_.script()};

# if we need to save the script to a file, we just add out-file at the end of the code
dir sqlserver:\sql\NTSRVTEST11\default\databases\AdventureWorks2012\tables | % {$_.foreignkeys } |  % {$_.script()} | out-file "c:\temp\fk.sql" -force;

# script out all foreign key deletion in T-SQL
dir sqlserver:\sql\NTSRVTEST11\default\databases\AdventureWorks2012\tables |% {$_.foreignkeys } |  % {"alter table $($_.parent) drop $_;"};

#script out all stored procedures
dir sqlserver:\sql\NTSRVTEST11\SQL2K8R2\databases\AdventureWorks2008R2\StoredProcedures | % {$_.script()+'go'};

#script out views with prefix as 'vEmployee'
dir sqlserver:\sql\NTSRVTEST11\SQL2K8R2\databases\AdventureWorks2008R2\Views | ? {$_.name -like 'vEmployee*' } | % {$_.script()+'go'};

#script out all DDL triggers
dir sqlserver:\sql\NTSRVTEST11\SQL2K8R2\databases\AdventureWorks2008R2\Triggers | % {$_.script()+'go'};

#script out UDFs
dir sqlserver:\sql\NTSRVTEST11\SQL2K8R2\databases\AdventureWorks2008R2\UserDefinedFunctions | % {$_.script()+'go'};

#script out SQL Server Agent Jobs whose name is 'ps test' and save it to a file at c:\temp\job.sql, if the file exist, just append the script to it
dir sqlserver:\sql\NTSRVTEST11\SQL2K8R2\jobserver\jobs | ? {$_.name -eq 'ps test'}| % {$_.script()+'go'} | out-file c:\temp\job.sql -append;
