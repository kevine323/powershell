<#
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
#>
clear-host
$Server = "SQLDBA\SQL2014" #Server to execute query from 
$strPath="c:\temp\EBR.xls" #path of file to read from 

$Command = "Insert into TMWApps..EBR Select " #Static Command to concatonate
$ShowCommands = "Y"
$ExecCommands = "N"

$Commands = @()

#Excel Setup
$objExcel=New-Object -ComObject Excel.Application
$objExcel.Visible=$false
$WorkBook=$objExcel.Workbooks.Open($strPath)
$worksheet = $workbook.sheets.item("sheet1")
$intRowMax =  ($worksheet.UsedRange.Rows).count
$Columnnumber = 1

for($intRow = 1 ; $intRow -le $intRowMax ; $intRow++) #introw = 2 if there are headers
{
 $Commands += $Command +  $worksheet.cells.item($intRow,$ColumnNumber).value2 #add static $Command and value of Excel cell to array
 #$name = $worksheet.cells.item($intRow,$ColumnNumber).value2
 If($ShowCommands -eq "Y")
   {$Command +  "'"+$worksheet.cells.item($intRow,$ColumnNumber).value2+"'" + "," + "'"+$worksheet.cells.item($intRow,2).value2+"'"} }

If($ExecCommands -eq "Y")
{
    foreach($row in $Commands)
    {
      Invoke-Sqlcmd -Query $row -ServerInstance $Server
    } 
}

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($objExcel) #Kill Excel