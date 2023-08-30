#Import-Module sqlpsx

'VBDSGPSQL1' | ForEach-Object {
Get-SqlErrorLog  -sqlserver $_ | Where-object { (     $_.logdate -ge ((Get-Date).addminutes(-500)))} | ft -a
                   # -and $_.Text -match '(log)' `
                   # -and $_.Text -notmatch '(without errors|found 0 errors)'} `
                   
 }