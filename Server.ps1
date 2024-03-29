############################################################################################
#Get Users In The DB And The Roles They Are In
############################################################################################

foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
     #Get Databases That Are Online
     $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
     $GetMaster = "Select Name From Sys.Databases Where State = 0"
     #SQL For Database Info
     
     $GetRoleInfo = "  Select DP2.Name as [PrincipalName]
                             ,TEMP.Name as [RoleName]
                             ,DB_NAME() as [Database]
                             ,@@SERVERNAME as [ServerName]
                        From sys.database_principals DP2 inner join (Select Member_Principal_ID, DP.Name 
                                                                       From sys.database_role_members DRM inner join sys.database_principals DP
                                                                         On DRM.Role_Principal_ID = DP.Principal_ID
                                                                      Where DP.Type = 'R') TEMP
                          on DP2.Principal_ID = TEMP.Member_Principal_ID     
                       Where DP2.Name <> 'dbo'"
                       
     #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn)
     #Create Data Table For Databases
     $MasterDT  = new-object System.Data.DataTable
     #Create Data Table For Database Information
     $DB_DT  = new-object System.Data.DataTable
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)
     
     foreach ($database in $MasterDT.rows)
       {
       $Name = $database.name
       $DBConn = "server=$svr;database=$Name;uid=sa;pwd=qrys93xx"           
          
       $DB_DA  = new-object System.Data.SQLClient.SQLDataAdapter($GetRoleInfo,$DBConn)
       
       $DB_DA.fill($DB_DT)        
       $DB_DT | Format-Table -AutoSize
       }
     $DB_DT | Export-Csv $("c:\temp\"+$svr+"_UsersRoles.csv") -NoType -ErrorAction SilentlyContinue   
     }
 
############################################################################################
#Get Users In The DB
############################################################################################
    
foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
     #Get Databases That Are Online
     $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
     $GetMaster = "Select Name From Sys.Databases Where State = 0"
     #SQL For Database Info
     
     $GetUserInfo = " Select Name
                            ,db_Name() as DBName
                        from sysusers
                       Where gid = 0
                         and Name not in ('public','dbo','guest','sys','INFORMATION_SCHEMA')
                         and hasdbaccess = 1"
                       
     #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn)
     #Create Data Table For Databases
     $MasterDT  = new-object System.Data.DataTable
     #Create Data Table For Database Information
     $DB_DT  = new-object System.Data.DataTable
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)
     
     foreach ($database in $MasterDT.rows)
       {
       $Name = $database.name
       $DBConn = "server=$svr;database=$Name;uid=sa;pwd=qrys93xx"           
      
       $DB_DA  = new-object System.Data.SQLClient.SQLDataAdapter($GetUserInfo,$DBConn)
       
       $DB_DA.fill($DB_DT)        
       $DB_DT | Format-Table -AutoSize
       }
     $DB_DT | Export-Csv $("c:\temp\"+$svr+"_Users.csv") -NoType -ErrorAction SilentlyContinue   
    }
    
############################################################################################
#Get Database Information
############################################################################################
    
foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
     #Get Databases That Are Online
     $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
     $GetMaster = "Select Name From Sys.Databases Where State = 0"
     #SQL For Database Info
     
     $GetUserInfo = " SELECT  
                            db_Name() AS DatabaseName,  
                            CAST(sysfiles.size/128.0 AS int) AS FileSize,  
                            sysfiles.name AS LogicalFileName, 
                            sysfiles.filename AS PhysicalFileName,  
                            CONVERT(sysname,DatabasePropertyEx(db_Name(),'Status')) AS Status,  
                            CONVERT(sysname,DatabasePropertyEx(db_Name(),'Updateability')) AS Updateability,  
                            CONVERT(sysname,DatabasePropertyEx(db_Name(),'Recovery')) AS RecoveryMode,  
                            CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name,'SpaceUsed') AS int)/128.0 AS int) AS FreeSpaceMB,  
                            CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,'SpaceUsed') AS int)/128.0)/(sysfiles.size/128.0)) AS decimal(4,2))) AS varchar(8)) + '%' AS FreeSpacePct,  
                            GETDATE() as PollDate 
                       FROM dbo.sysfiles"
                       
     #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn)
     #Create Data Table For Databases
     $MasterDT  = new-object System.Data.DataTable
     #Create Data Table For Database Information
     $DB_DT  = new-object System.Data.DataTable
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)
     
     foreach ($database in $MasterDT.rows)
       {
       $Name = $database.name
       $DBConn = "server=$svr;database=$Name;uid=sa;pwd=qrys93xx"           
      
       $DB_DA  = new-object System.Data.SQLClient.SQLDataAdapter($GetUserInfo,$DBConn)
       
       $DB_DA.fill($DB_DT)        
       $DB_DT | Format-Table -AutoSize
       }
     $DB_DT | Export-Csv $("c:\temp\"+$svr+"_FileSize.csv") -NoType -ErrorAction SilentlyContinue   
    }   
    
############################################################################################
#Get Basic Server Information
############################################################################################

#Create Data Table 
$MasterDT  = new-object System.Data.DataTable   
foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
    $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
    $GetMaster = "DECLARE @ServiceStart INT
                  DECLARE @ServiceRunningAs varchar(30) 

                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Services\MSSQLSERVER', 
                                         N'start', @ServiceStart OUTPUT, N'no_output'
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Services\MSSQLSERVER', 
                                         N'ObjectName', @ServiceRunningAs OUTPUT, N'no_output'
                  DECLARE @AgentStart INT
                  DECLARE @AgentRunningAs varchar(30) 

                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Services\SQLSERVERAGENT', 
                                         N'start', @AgentStart OUTPUT, N'no_output'
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 'SYSTEM\CurrentControlSet\Services\SQLSERVERAGENT', 
                                         N'ObjectName', @AgentRunningAs OUTPUT, N'no_output'
     
                  DECLARE @AuditLvl INT 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
                                         N'AuditLevel', @AuditLvl OUTPUT, N'no_output'
                                            
                  DECLARE @DfltPath varchar(200) 
                  DECLARE @DfltLgPath varchar(200) 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
                                         N'DefaultData', @DfltPath OUTPUT, N'no_output'
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', 
                                         N'DefaultLog', @DfltLgPath OUTPUT, N'no_output'
  
                  DECLARE @Resrt_Value int 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
										 N'RestartSQLServer', @Resrt_Value OUTPUT, N'no_output'

                  DECLARE @Mon_Resrt_Value int 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                         N'MonitorAutoStart', @Mon_Resrt_Value OUTPUT, N'no_output'
           
                  DECLARE @Use_DBM int 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                         N'UseDatabaseMail', @Use_DBM OUTPUT, N'no_output'
  
                  DECLARE @Ml_Prof varchar(100) 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                         N'DatabaseMailProfile', @Ml_Prof OUTPUT, N'no_output'
   
                  DECLARE @FS_Opr varchar(100) 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                         N'AlertFailSafeOperator', @FS_Opr OUTPUT, N'no_output'
  
                  DECLARE @EM_Not int 
                  EXECUTE master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', 
                                         N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent',
                                         N'AlertNotificationMethod', @EM_Not OUTPUT, N'no_output'
 
                  SELECT CONVERT(varchar(128),Serverproperty('Servername')) AS Server,
                         CONVERT(varchar(100),Serverproperty('ProductVersion')) AS Product_Version,
                         CONVERT(varchar(100),Serverproperty('ProductLevel')) AS Product_Level,
                    CASE
                        WHEN Serverproperty('EngineEdition') = 1 THEN 'Personal Edition'
                        WHEN Serverproperty('EngineEdition') = 2 THEN 'Standard Edition'
                        WHEN Serverproperty('EngineEdition') = 3 THEN 'Enterprise Edition'
                        WHEN Serverproperty('EngineEdition') = 4 THEN 'Express Edition'
                    END AS Engine_Edition,
                    COALESCE(CONVERT(varchar(128),Serverproperty('InstanceName')),' ') AS Instance_Name,
                    CONVERT(varchar(128),Serverproperty('ComputerNamePhysicalNetBIOS')) AS Computer_Physical_Name,
                    CONVERT(varchar(100),Serverproperty('BuildClrVersion')) AS Build_Clr_Version,
                    CONVERT(varchar(100),Serverproperty('Collation')) AS Collation,
                    CASE
                        WHEN CONVERT(varchar(100),Serverproperty('EngineID')) = -1253826760 THEN 'Desktop Edition'
                        WHEN Serverproperty('EngineID') = -1592396055 THEN 'Express Edition'
                        WHEN Serverproperty('EngineID') = -1534726760 THEN 'Standard Edition'
                        WHEN Serverproperty('EngineID') = 1333529388 THEN 'Workgroup Edition'
                        WHEN Serverproperty('EngineID') = 1804890536 THEN 'Enterprise Edition'
                        WHEN Serverproperty('EngineID') = -323382091 THEN 'Personal Edition'
                        WHEN Serverproperty('EngineID') = -2117995310 THEN 'Developer Edition'
                        WHEN Serverproperty('EngineID') = 610778273 THEN 'Enterprise Evaluation Edition'
                        WHEN Serverproperty('EngineID') = 1044790755 THEN 'Windows Embedded SQL'
                        WHEN Serverproperty('EngineID') = 4161255391 THEN 'Express Edition with Advanced Services'
                        ELSE CONVERT(varchar(128),Serverproperty('EngineID')) 
                    END AS Platform,
                    CASE
                        WHEN CONVERT(varchar(100),Serverproperty('IsClustered')) = 1 THEN 'Y'
                        WHEN Serverproperty('IsClustered') = 0 THEN 'N'
                        ELSE NULL
                    END AS Clustered_Instance,
       
                    (SELECT login_time FROM sysprocesses WHERE spid = 1) as Last_Start_Date,
                    COALESCE((SELECT CASE value WHEN 1 THEN 'Y' ELSE 'N' END from sysconfigures WHERE comment like '%ole automation%'),'N') as Ole_Automation_Enabled,
                    COALESCE((SELECT CASE value WHEN 1 THEN 'Y' ELSE 'N' END from sysconfigures WHERE comment like '%command shell%'),'N') as  Command_Shell_Enabled,
                    (SELECT value from sysconfigures WHERE comment = 'Default fill factor percentage') as  Default_Fill_Factor,
                    @DfltPath as Default_Data_Location
                    , @DfltLgPath as Default_Log_Location
                    , @ServicerunningAs as SQL_Service_Account
                    ,CASE @ServiceStart 
                        WHEN 0 THEN 'Boot' 
                        WHEN 1 THEN 'System'
                        WHEN 2 THEN 'Automatic'
                        WHEN 3 THEN 'Manual'
                        WHEN 4 THEN 'Disabled'
                    ELSE 'Service Not Found'
                    END as SQL_Service_Startup_Type
                    , @AgentRunningAs as SQL_Agent_Account
                    , CASE @AgentStart 
                        WHEN 0 THEN 'Boot' 
                        WHEN 1 THEN 'System'
                        WHEN 2 THEN 'Automatic'
                        WHEN 3 THEN 'Manual'
                        WHEN 4 THEN 'Disabled'
                        ELSE 'Service Not Found'
                     END as SQL_Agent_Startup_Type
                    , CASE @AuditLvl 
                        WHEN 0 then 'None'
                        WHEN 1 then 'Successful Logins'
                        WHEN 2 then 'Failed Logins' 
                        WHEN 3 then 'Failed and Successful Logins'
                        ELSE 'Unknown'
                    END as Audit_Logins
                    , CASE @Resrt_Value 
                        WHEN 1 THEN 'Y'
                        ELSE 'N'
                      END as SQL_Service_Auto_Restart
                    , CASE @Mon_Resrt_Value 
                    WHEN 1 THEN 'Y'
                    ELSE 'N'
                    END as SQL_Agent_Auto_Restart
                    , CASE @Use_DBM 
                        WHEN '1' THEN 'Y'
                        ELSE 'N'
                      END as Database_Mail_Set
                    , CASE COALESCE(@Ml_Prof,'NULL')
                        WHEN 'NULL' THEN ' '
                        ELSE @Ml_Prof
                      END as Database_Mail_Profile_Enabled
                    , CASE COALESCE(@FS_Opr, 'NULL') 
                        WHEN 'NULL' THEN ' '
                        ELSE @FS_Opr
                      END as Failsafe_Operator
                    , @EM_Not as Failsafe_Operator_Notification"                 
      
      #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn) 
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)                   
     
   }
     $MasterDT | Format-Table -AutoSize
     $MasterDT | Export-Csv $("c:\temp\ServerInfo.csv") -NoType -ErrorAction SilentlyContinue  
     
############################################################################################
#Get Database Table Row Information
############################################################################################
    
foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
     #Get Databases That Are Online
     $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
     $GetMaster = "Select Name From Sys.Databases Where State = 0"
     #SQL For Database Info
     
     $GetUserInfo = " -- Table and row count information    
                      SELECT DB_Name() as DBName,
                             OBJECT_NAME(ps.[object_id]) AS [TableName],  
                             i.name AS [IndexName], 
                             SUM(ps.row_count) AS [RowCount] 
                        FROM sys.dm_db_partition_stats AS ps INNER JOIN sys.indexes AS i  
                          ON i.[object_id] = ps.[object_id]  
                         AND i.index_id = ps.index_id  
                       WHERE i.type_desc IN ('CLUSTERED','HEAP') 
                         AND i.[object_id] > 100 
                         AND OBJECT_SCHEMA_NAME(ps.[object_id]) <> 'sys' 
                       GROUP BY ps.[object_id], i.name 
                       ORDER BY SUM(ps.row_count) DESC;"
                       
     #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn)
     #Create Data Table For Databases
     $MasterDT  = new-object System.Data.DataTable
     #Create Data Table For Database Information
     $DB_DT  = new-object System.Data.DataTable
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)
     
     foreach ($database in $MasterDT.rows)
       {
       $Name = $database.name
       $DBConn = "server=$svr;database=$Name;uid=sa;pwd=qrys93xx"           
      
       $DB_DA  = new-object System.Data.SQLClient.SQLDataAdapter($GetUserInfo,$DBConn)
       
       $DB_DA.fill($DB_DT)        
       $DB_DT | Format-Table -AutoSize
       }
     $DB_DT | Export-Csv $("c:\temp\"+$svr+"_TableRowInfo.csv") -NoType -ErrorAction SilentlyContinue   
    }        
    
############################################################################################
#Get Object Access
############################################################################################
    
foreach ($svr in get-content "c:\temp\PS_Servers.txt")
    {
     #Get Databases That Are Online
     $MasterConn = "server=$svr;database=master;uid=sa;pwd=qrys93xx"
     $GetMaster = "Select Name From Sys.Databases Where State = 0"
     #SQL For Database Info
     
     $GetObjectInfo = " SELECT
                        sysU.name, sysO.name, permission_name ,
                        granted_by = suser_name(grantor_principal_id)
                        ,db_Name()
                        FROM sys.database_permissions
                        JOIN sys.sysusers sysU on grantee_principal_id = uid
                        JOIN sys.sysobjects sysO on major_id = id
                        order by sysU.name"
                       
     #Create New DataAdapter     
     $MasterDA  = new-object System.Data.SQLClient.SQLDataAdapter($GetMaster,$MasterConn)
     #Create Data Table For Databases
     $MasterDT  = new-object System.Data.DataTable
     #Create Data Table For Database Information
     $DB_DT  = new-object System.Data.DataTable
     #Fill Data Table With Database On server
     $MasterDA.fill($MasterDT)
     
     foreach ($database in $MasterDT.rows)
       {
       $Name = $database.name
       $DBConn = "server=$svr;database=$Name;uid=sa;pwd=qrys93xx"           
      
       $DB_DA  = new-object System.Data.SQLClient.SQLDataAdapter($GetObjectInfo,$DBConn)
       
       $DB_DA.fill($DB_DT)        
       $DB_DT | Format-Table -AutoSize
       }
     $DB_DT | Export-Csv $("c:\temp\"+$svr+"_ObjectAccess.csv") -NoType -ErrorAction SilentlyContinue   
    }        
    
    