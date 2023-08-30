#Import-Module sqlpsx


Get-SqlTransaction "SQLAnalytics" "TMWApps" | ft -a
 
get-help get-sqltransaction -examples

get-sqlprocess "sqlanalytics" | where-object {$_.status -match '[a-z]' } | ft -a