##
# Eleos-Ftp-Image-Get
#
# To use:
#   Update the imageDestinationPath to be the desired target folder where image files should be routed;
#   and ensure the credentials are correct for your env
# To get event logs, run this as an Administrator:
#   New-EventLog -Source "EleosDownloader" -LogName "Application"
##
param (
  [switch]$useProduction        = $false,
  [string]$imageDestinationPath = "C:\Tributary\TAC\Email2DB_Billing_MB\Input",
  [string]$eleosFtpServer       = "ftp://ftp.driveaxleapp.com",
  [string]$ftpUsername          = "",
  [string]$ftpPassword          = ""
)

function Log-Both($message) {
    Write-Host (Get-Date) $message
    Write-EventLog -LogName "Application" -Source "EleosDownloader" -EventID 3001 -Message $message
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
        Log-Both("Failed: $_")
        Exit
    }

    $stream   = $response.GetResponseStream()

#    Log-Both $response.StatusCode -nonewline
#    Log-Both $response.StatusDescription


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
        Log-Both "Failed: $_"
        Exit
    }

#    Log-Both $response.StatusDescription " write to $target"
    $stream   = $response.GetResponseStream()

    try {
        $imageFile = New-Object IO.FileStream ($target, [IO.FileMode]::Create)
    } catch {
        Log-Both "Failed: $_"
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
Log-Both "Starting"
if(Test-Path $imageDestinationPath) {
    $tempDirectory = New-TemporaryDirectory
    Log-Both "    Retrieving images from '$eleosFtpServer'"
    $fileList = Ftp-GetFileList $eleosFtpServer $ftpUsername $ftpPassword

    $totalNumFiles = 0
    foreach ($imgFile in $fileList) {
        if($imgFile -ne '') {
            $fileName = $imgFile.ToString().Trim()
            Log-Both "      found '$fileName'"

            $source = $eleosFtpServer          + '/' + $fileName
            $target = Join-Path $tempDirectory.FullName $fileName

            Ftp-GetFile $source $target $ftpUsername $ftpPassword
            $totalNumFiles = $totalNumFiles + 1
        }
    }

    Log-Both "    Total Image Files Retrieved:  $totalNumFiles"

    foreach ($imgFile in $fileList) {
        if($imgFile -ne '') {
            $fileName = $imgFile.ToString().Trim()

            $source = Join-Path $tempDirectory.FullName $fileName
            $target = Join-Path $imageDestinationPath $fileName

            Log-Both "      moving '$fileName' image to '$imageDestinationPath'"
            Move-Item -Path $source -Destination $target

            $txtFileName = $fileName.Remove(($lastIndex = $fileName.LastIndexOf(".")), ".pdf".Length).Insert($lastIndex, ".txt")
            $target = Join-Path $imageDestinationPath $txtFileName
            Log-Both "      creating '$txtFileName'"
            New-Item $target -type file
        }
    }
    Log-Both "      cleaning up"
    Remove-Item $tempDirectory -Force -Recurse
}
else {
    Log-Both "Aborting: '$imageDestinationPath' not found!"
}
Log-Both "Done"
