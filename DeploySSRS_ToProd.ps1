#Load Vars
$SourceSSRS = "http://cognosgate-t/ReportServer/ReportService2005.asmx"
$DestSSRS = "http://cognosgate/ReportServer/ReportService2005.asmx"
$TempFolder = "\\ntsrv\T_Datacent\TEMP\KevinE\DeployToProd\"
$DestPath = "/DeployToProd"

#Load Assemblies
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Xml.XmlDocument");
[void][System.Reflection.Assembly]::LoadWithPartialName("System.IO");

#Setup Proxies
$SourceReportServerUri = $SourceSSRS # "http://cognosgate-t/ReportServer/ReportService2005.asmx";
$SourceProxy = New-WebServiceProxy -Uri $SourceReportServerUri -Namespace SSRS.ReportingService2005 -UseDefaultCredential ;

$DestReportServerUri = $DestSSRS #"http://cognosgate-t/ReportServer/ReportService2005.asmx";
$DestProxy = New-WebServiceProxy -Uri $DestReportServerUri -Namespace SSRS.ReportingService2005 -UseDefaultCredential ;

#Get Items To Be Deployed/second parameter means recursive
$items = $SourceProxy.ListChildren("/DeployToProd", $true) | `
         select Type, Path, ID, Name | `
         Where-Object {$_.type -eq "Report"};
 
#create a timestamped folder
$folderName = Get-Date -format "yyyy-MMM-dd-hhmmtt";
$fullFolderName = "$TempFolder" + $folderName;
[System.IO.Directory]::CreateDirectory($fullFolderName) | out-null 

foreach($item in $items)
{
    #need to figure out if it has a folder name
    $subfolderName = split-path $item.Path;
    $reportName = split-path $item.Path -Leaf;
    $fullSubfolderName = $fullFolderName + $subfolderName;
    if(-not(Test-Path $fullSubfolderName))
    {
        #note this will create the full folder hierarchy
        [System.IO.Directory]::CreateDirectory($fullSubfolderName) | out-null
    }
 
    $rdlFile = New-Object System.Xml.XmlDocument;
    [byte[]] $reportDefinition = $null;
    $reportDefinition = $SourceProxy.GetReportDefinition($item.Path);
 
    #note here we're forcing the actual definition to be 
    #stored as a byte array
    #if you take out the @() from the MemoryStream constructor, you'll 
    #get an error
    [System.IO.MemoryStream] $memStream = New-Object System.IO.MemoryStream(@(,$reportDefinition));
    $rdlFile.Load($memStream);
 
    $fullReportFileName = $fullSubfolderName + "\" + $item.Name +  ".rdl";
    #Write-Host $fullReportFileName;
    $rdlFile.Save( $fullReportFileName);
}

$files = @(get-childitem $TempFolder *.rdl -rec|where-object {!($_.psiscontainer)})

$uploadedCount = 0

 foreach ($fileInfo in $files)    
 {            
    $file = [System.IO.Path]::GetFileNameWithoutExtension($fileInfo.FullName) 
    $percentDone = (($uploadedCount/$files.Count) * 100) 
    Write-Progress -activity "Uploading to $reportServerName$serverPath" -status $file -percentComplete $percentDone
    Write-Output "%$percentDone : Uploading $file to $reportServerName$serverPath"
    $bytes = [System.IO.File]::ReadAllBytes($fileInfo.FullName)
    $warnings = $DestProxy.CreateReport($file, $DestPath, $true, $bytes, $null)
    if ($warnings)        
    {            
        foreach ($warn in $warnings)            
        {                
            Write-Warning $warn.Message            
        }        
    }                 
    
    $uploadedCount += 1    
 }    
 
 
 
 
 #Get Items To Be Deployed/second parameter means recursive
$items = $SourceProxy.ListChildren("/DeployToProd", $true) | `
         select Type, Path, ID, Name | `
         Where-Object {$_.type -eq "Report"};
 
#create a timestamped folder
$folderName = Get-Date -format "yyyy-MMM-dd-hhmmtt";
$fullFolderName = "$TempFolder" + $folderName;
[System.IO.Directory]::CreateDirectory($fullFolderName) | out-null 

foreach($item in $items)
{
    #need to figure out if it has a folder name
    $subfolderName = split-path $item.Path;
    $reportName = split-path $item.Path -Leaf;
    $fullSubfolderName = $fullFolderName + $subfolderName;
    if(-not(Test-Path $fullSubfolderName))
    {
        #note this will create the full folder hierarchy
        [System.IO.Directory]::CreateDirectory($fullSubfolderName) | out-null
    }
 
    $rdlFile = New-Object System.Xml.XmlDocument;
    [byte[]] $reportDefinition = $null;
    $reportDefinition = $Proxy.GetReportDefinition($item.Path);
 
    #note here we're forcing the actual definition to be 
    #stored as a byte array
    #if you take out the @() from the MemoryStream constructor, you'll 
    #get an error
    [System.IO.MemoryStream] $memStream = New-Object System.IO.MemoryStream(@(,$reportDefinition));
    $rdlFile.Load($memStream);
 
    $fullReportFileName = $fullSubfolderName + "\" + $item.Name +  ".rdl";
    #Write-Host $fullReportFileName;
    $rdlFile.Save( $fullReportFileName);
}