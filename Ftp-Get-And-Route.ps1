##
# Ftp-Get-And-Route
#
# To use:
#   Edit the imageDestinationPath to be the desired target folder where image files should be routed;
#   designated whether to use Prod or Sandbox credentials by toggling 'useProduction' accordingly
##
param (
  [switch]$useProduction        = $false,
  [string]$imageDestinationPath = "C:\Temp\Eleos",
  [string]$eleosFtpServer       = "ftp://ftp.driveaxleapp.com",
  [string]$prodFtpUsername      = "development@ryder.com",
  [string]$prodFtpPassword      = "HLSE3gajiE273lMk",
  [string]$devFtpUsername       = "development@ryder.com",
  [string]$devFtpPassword       = "HLSE3gajiE273lMk"
)

if($useProduction) {
    $ftpUsername = $prodFtpUsername
    $ftpPassword = $prodFtpPassword
} else {
    $ftpUsername = $devFtpUsername
    $ftpPassword = $devFtpPassword
}

function New-TemporaryDirectory {
  $parent = [System.IO.Path]::GetTempPath()
  $name   = [System.IO.Path]::GetRandomFileName()
  New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function Ftp-GetFileList($server, $username, $password)
{
    $uri = [system.URI]$server
    $request = [System.Net.FtpWebRequest]::create($uri)  

    $request.Credentials =  
        New-Object System.Net.NetworkCredential($username, $password)
 
    $request.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $request.KeepAlive  = $true
    $request.UsePassive = $true
    $request.Timeout    = 30000

    try {
        $response = $request.GetResponse()
    } catch {
        Write-Host "Failed: $_"
        Exit
    }

    $stream   = $response.GetResponseStream()

#    Write-Host $response.StatusCode -nonewline
#    Write-Host $response.StatusDescription


    $stream = $response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream,'UTF-8')
    $fileList = $reader.ReadToEnd()

    $reader.Close()
    $response.Close()

    return $fileList.Split("`n")
}

function Ftp-GetFile($source, $target, $username, $password)
{
    $uri = [system.URI]$source
    $request = [System.Net.FtpWebRequest]::create($uri)  

    $request.Credentials =  
     New-Object System.Net.NetworkCredential($username, $password)
 
    $request.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
    $request.Timeout   = 15000
    $request.UseBinary = $true
    $request.KeepAlive = $true
    $request.EnableSsl = $false

    try {
        $response = $request.GetResponse()
    } catch {
        Write-Host "Failed: $_"
        Exit
    }

#    Write-Host $response.StatusDescription " write to $target"
    $stream   = $response.GetResponseStream()

    try {
        $imageFile = New-Object IO.FileStream ($target, [IO.FileMode]::Create)
    } catch {
        Write-Host "Failed: $_"
        $stream.Close()
        $response.Close()
        Exit
    }

    [byte[]]$readBuffer = New-Object byte[] 1024
    $readLength = 0
    do {
        $readLength = $stream.Read($readBuffer, 0, 1024)
        $imageFile.Write($readBuffer, 0, $readLength)
    } while ($readLength -ne 0)
    $imageFile.Close()
    $stream.Close()
    $response.Close()
}

clear
Write-Host "Starting"
if(Test-Path $imageDestinationPath) {
    $tempDirectory = New-TemporaryDirectory
    Write-Host "    Retrieving images from "$eleosFtpServer
    $fileList = Ftp-GetFileList $eleosFtpServer $ftpUsername $ftpPassword

    $totalNumFiles = 0
    foreach ($imgFile in $fileList) {
        if($imgFile -ne '') {
            $fileName = $imgFile.ToString().Trim()
            Write-Host "      found "$fileName

            $source = $eleosFtpServer          + '/' + $fileName
            $target = Join-Path $tempDirectory.FullName $fileName

            Ftp-GetFile $source $target $ftpUsername $ftpPassword
            $totalNumFiles = $totalNumFiles + 1
        }
    }

    Write-Host "    Total Image Files Retrieved: " $totalNumFiles

    foreach ($imgFile in $fileList) {
        if($imgFile -ne '') {
            $fileName = $imgFile.ToString().Trim()
            Write-Host "      expanding "$fileName

            $tempImgDirectory = New-TemporaryDirectory
            $target = Join-Path $tempDirectory.FullName $fileName
            Expand-Archive -Path $target -DestinationPath $tempImgDirectory

            Get-ChildItem -Path $tempImgDirectory -Include *.xml -Recurse | 
            Foreach-Object {
                #Remove-Item $_.FullName
                Write-Host  $_.FullName
            }
            Get-ChildItem -Path $tempImgDirectory -Include *.json -Recurse | 
            Foreach-Object {
                #Remove-Item $_.FullName
                Write-Host  $_.FullName
            }

            # ensure filename is unique when staged for processing
            # else, risk overwriting an image file if imaging system
            # cannot keep up with number of retrieved images
            Get-ChildItem $tempImgDirectory | 
            Foreach-Object {
                $randomNum = [string](Get-Random -Maximum 99999999)
                $uniqFileName = $randomNum + $_.Extension
                $newImgFileName = Join-Path $imageDestinationPath $uniqFileName
                while(Test-Path $newImgFileName) {
                    $randomNum = [string](Get-Random -Maximum 99999999)
                    $uniqFileName = $randomNum + $_.Extension
                    $newImgFileName = Join-Path $imageDestinationPath $uniqFileName
                }
                Write-Host "      moving image to "$imageDestinationPath
                Move-Item -Path $_.FullName -Destination $newImgFileName
            }
            Remove-Item $tempImgDirectory -Force -Recurse
        }
    }
    Write-Host "      cleaning up"
    Remove-Item $tempDirectory -Force -Recurse
}
else {
    Write-Host "Aborting: '"$imageDestinationPath"' not found!"
}
Write-Host "Done"

