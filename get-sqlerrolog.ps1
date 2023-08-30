function Get-SqlErrorLog {
    [cmdletbinding()]
    param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true,ValueFromPipelineByPropertyName = $true)] [string[]]$sqlserver ,
    [Parameter(Position=1, Mandatory=$false)] [int]$lognumber=0
    )

    Begin {
        [Reflection.Assembly]::LoadWithPartialName('microsoft.sqlserver.smo') | Out-Null

    }

    process {
        foreach($ServerS in $sqlserver) {
            $server = new-object ("Microsoft.SqlServer.Management.Smo.Server") $ServerS
            Write-Verbose "Get-SqlErrorLog $($server.Name)"
            $server.ReadErrorLog($lognumber)

        }
    }
    
} #Get-SqlErrorLog

