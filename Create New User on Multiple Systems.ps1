<#
Purpose: to create a user on multiple systems
#>

######################################################
#Required
$UserName = "[KevinTest]"
$IsSQL    = "Y"
$Password = "Test"

#Options
$ShowCommandOnly = "Y"
$MustChange      = "N"
$DefaultDatabase = "[Master]"
$CheckExpiration = "OFF" #Cant be ON if CheckPolicy is OFF
$CheckPolicy     = "OFF"

#Servers To be executed against
$ServerList = @("SQLAnalytics-T"
               ,"SQLAnalytics-PP"
               ,"SQLAnalytics")
#######################################################        

#Create Command
$SQL = "CREATE LOGIN $UserName "
If($IsSQL -eq "N")
{
    $SQL += "FROM WINDOWS"
    $SQL += ", DEFAULT_DATABASE=[master]" #Default Database
}
Else
{
    $SQL += "WITH PASSWORD = N'$Password'"
    IF($MustChange -eq "Y") #MustChange
        {$SQL = $SQL + " Must_Change"} 
    $SQL += ", DEFAULT_DATABASE=[master]" #Default Database
    $SQL += ", CHECK_EXPIRATION = $CheckExpiration" #CheckExpire
    $SQL += ", CHECK_POLICY = $CheckPolicy" #CheckPolicy
}


ForEach($Server in $ServerList)
{
    Try
    {
        If($ShowCommandOnly -eq "Y") #Show Command Only
            {$SQL}
        Else
            {Invoke-SQLCMD -query $SQL -ServerInstance $Server} #Execute Command Against Server
    }
    Catch [System.Exception]
    {
        $ex = $_.Exception
        Write-Host $ex.Message
    }
    Finally
    {
        "--Create User on $Server Finshed"       
    }
}   