[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo') | Out-Null

$FilePath = 'c:\temp\sqljobs\'
#Get List Of Servers From SQL Overview
$SQLOverviewConn = "Server=SQLDW\Warehouse;Integrated Security=SSPI"
$SQLOverviewQuery = "SELECT [Server] as Name FROM [SQL_Overview].[dbo].[SSIS_ServerList] WHERE [Skip_SQL_Overview] = 0"

#Create New DataAdapter     
$SQLOverviewDA  = new-object System.Data.SQLClient.SQLDataAdapter($SQLOverviewQuery,$SQLOverviewConn)
#Create Data Table For Servers
$SQLOverviewDT  = new-object System.Data.DataTable

#Fill Data Table With Database On server
$SQLOverviewDA.fill($SQLOverviewDT)

#If I want get it from a file
#foreach ($server in get-content "c:\temp\PS_Servers.txt")
foreach ($server in $SQLOverviewDT.rows)
       { 
       $SvrName = $server.Name      
       $ServerObject = New-Object ('Microsoft.SqlServer.Management.Smo.Server') $SvrName 
       $jobs = $ServerObject.JobServer.Jobs #| where-object {$_.category -eq "[your category]"}                    
       if ($jobs -ne $null)
        {         
            ForEach ( $job in $jobs )
                {
                #Replace '\' in instanced sql servers
                $SvrName = [System.Text.RegularExpressions.Regex]::Replace($SvrName,"[^0-9a-zA-Z]","_")               
                #Test for folder existence
                $DestinationFolder = $FilePath + $SvrName                 
                if(!(Test-Path -path $DestinationFolder))
                  {
                    New-Item $DestinationFolder -Type Directory
                  }             
                  
                #Replace '\' in job name 
                $jobName = [System.Text.RegularExpressions.Regex]::Replace($job.Name,"[^0-9a-zA-Z]","_")                                 
                $FileName = $DestinationFolder + '\' + $jobname + ".sql"
                $job.Script() | Out-File -filepath $FileName                
                }
        }
}