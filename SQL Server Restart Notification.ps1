param([Parameter(Mandatory=$true)]  [String]$version = '11.0.0.0',
      [Parameter(Mandatory=$true)] [String]$instance="SQLGP-PP"
      )

add-type -AssemblyName "microsoft.sqlserver.smo, version=$version, Culture=neutral, PublicKeyToken=89845dcd8080cc91";#version should be changed according to your installed sql version, sql2008=10.0.0.0
 
$info=get-eventlog -logname System -entrytype information -source User32 -computer . -after (get-date).addhours(-12) -message "The process * has initiated * on behalf of *"  | select timegenerated, message -first 1
 
 
if ($info -ne $null)
{
    $info.message -match "on behalf of user (.*?) for"
    [string]$user=$matches[1];
 
    $svr = new-object 'microsoft.sqlserver.management.smo.server' $instance # change <SQLInstance_Name> accordingly
    $curr=$svr.ReadErrorLog(0) | Where-Object {$_.Text -match 'Recovery is complete'} | select LogDate -last 1;
 
    [string]$msg='';
    if ($curr -ne $null)
    {
        $prev = $svr.ReadErrorLog(1) | select LogDate -last 1;
 
        $d=$curr.logdate - $prev.LogDate;
        $msg += "The downtime window was from $(($prev.LogDate).ToString('yyyy-MM-dd HH:mm:ss')) to $(($curr.Logdate).toString('yyyy-MM-dd HH:mm:ss')) `r`n";
        $msg += "Total downtime was $($d.hours) hours, $($d.Minutes) minutes and $($d.Seconds) seconds `r`n`r`n";
    }
 
    $msg +=  $info.Message;
 
    [string]$qry=@"
    exec msdb.dbo.sp_send_dbmail @recipients='kevin.eckart@usa-truck.com', @subject='Server was rebooted at $($info.TimeGenerated) by $($user)'
    , @body= '$($msg)';
"@;
 
    $svr.databases['msdb'].ExecuteNonQuery($qry);    
   
}