<#
Add-PSSnapin SqlServerCmdletSnapin100
Add-PSSnapin SqlServerProviderSnapin100
Import-Module activedirectory
#>
Clear-Host
<#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Setup
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#>
$ServerName = "SQLAnalytics-T"  #SQL Server Commands Will Be Ran Against
$cn = new-object System.Data.SqlClient.SqlConnection "server=$ServerName;Integrated Security=sspi" #create a Connection to the SQL Server database
$strFileName = "c:\temp\test.xls" #Location of Excel Spreadsheet
[regex]$r="[^a-zA-Z]" #Setup RegEx for Allowable Characters

If (test-path $strFileName) {Remove-Item $strFileName}  #Remove File If It Exists

#Array of Commands (Each Command Must Have a Cooresponding Dataset)
$Commands = @("EXEC SP_helprotect", 
              "EXEC SP_helpuser", 
              "EXEC SP_helpsrvrolemember", 
              "EXEC SP_helprolemember", 
              "EXEC SP_dbfixedrolepermission", 
              "EXEC SP_srvrolepermission",
              "Select * From sys.server_principals",
              "Select * From sys.sql_logins")

#Create Array of Datasets (Each Dataset Must Have a Cooresponding Command)
$DataSets = @()
$DataSets +=  new-object "System.Data.DataSet" "DS_HelpProtect"
$DataSets +=  new-object "System.Data.DataSet" "DS_HelpUser"
$DataSets +=  new-object "System.Data.DataSet" "DS_HelpSRVRoleMember"
$DataSets +=  new-object "System.Data.DataSet" "DS_HelpRoleMember"
$DataSets +=  new-object "System.Data.DataSet" "DS_DBFixedRolePermission"
$DataSets +=  new-object "System.Data.DataSet" "DS_SRVRolePermission"
$DataSets +=  new-object "System.Data.DataSet" "DS_Server_Principals"
$DataSets +=  new-object "System.Data.DataSet" "DS_Sql_Logins"


#Create Excel File
$Excel = New-Object -ComObject Excel.Application
$WorkBook = $Excel.Workbooks.Add()
#Excel Starts With 3 Sheets and Needs to Add 5 More (This gives a total of 8 Which is How Many Commands I Have)
$workbook.worksheets.add()
$workbook.worksheets.add()
$workbook.worksheets.add()
$workbook.worksheets.add()
$workbook.worksheets.add()

Clear-Host

$start=get-date
write-host $start

<#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
For Each Command Fill Sheet in Excel
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!#>
$DataSetNo = 0
foreach($command in $commands)
  {
    #Create a DataAdapter and Fill The Corresponding DataSet    
    $dataAdapter = new-object "System.Data.SqlClient.SqlDataAdapter" ($command, $cn)
    $dataAdapter.Fill($DataSets[$DataSetNo]) | Out-Null
    
    #Create an in-memory DataTable From the DataSet
    $dataTable = new-object "System.Data.DataTable"
    $dataTable = ($DataSets[$DataSetNo].Tables[0])
  
    #Build the Excel column heading:
    [Array] $getColumnNames = $dataTable.Columns | Select ColumnName;
    
    #Make the Current Excel Worksheet Number the Same as the DataSet Number we're on +1 (isnt 0 based)
    $CurrentSheet = $WorkBook.Worksheets.Item($DataSetNo+1)
    
    #Use RegEx to Get Rid of Invalid Chars Since We're Naming the Tab the Same as the Command Executed
    $command = $r.replace($command," ")
    
    #If the Command Is Too Long, use the First 31 Chars
    if ($command.length -ge 31)
      {$CurrentSheet.Name = $command.substring(0,31)}
    else
      {$CurrentSheet.Name = $command}
    
    #Build column header:
    [Int] $RowHeader = 1;
    foreach ($ColH in $getColumnNames)
        {
        $CurrentSheet.Cells.item(1, $RowHeader).font.bold = $true;
        $CurrentSheet.Cells.item(1, $RowHeader) = $ColH.ColumnName;
        $RowHeader++;
        }; 
        
    #Adding the data start in row 2 column 1:
    [Int] $rowData = 2;
    [Int] $colData = 1;        
     
    foreach ($rec in $dataTable.Rows)
        {
            foreach ($Coln in $getColumnNames)
                {
                    ## - Next line convert cell to be text only:
                    $CurrentSheet.Cells.NumberFormat = "@";                                                                            
                    $CurrentSheet.Cells.Item($rowData, $colData) = $rec.$($Coln.ColumnName).ToString();
                    $ColData++;
                };         
             $rowData++; 
             $ColData = 1;
        };
    
    #Extend Columns on the Sheet
    $xlsRng = $CurrentSheet.usedRange;
    $xlsRng.EntireColumn.AutoFit();              
    
    $DataSetNo++
}

#$Excel.Visible = $True
$end=get-date
write-host $end

#CleanUP
$WorkBook.SaveAs($strFileName,1)
$WorkBook.Close()
$Excel.quit()