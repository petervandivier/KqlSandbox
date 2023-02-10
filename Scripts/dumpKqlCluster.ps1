#Requires -Modules Invoke-AdxCmd

<#
.LINK
    https://github.com/petervandivier/Invoke-AdxCmd
.LINK
    https://stackoverflow.com/questions/75315624/powershell-function-to-query-azure-data-explorer
#>

Param(
    [Parameter(Mandatory)]
    [ValidateScript({$_.EndsWith(';Fed=True')})]
    [string]
    $clusterUrl
)

$PSDefaultParameterValues.'Invoke-AdxCmd:clusterUrl' = $clusterUrl

$null = $clusterUrl -match "//(.*?)\."
$clusterName = $Matches[1]

Push-Location $PsScriptRoot/..

$databases = Invoke-AdxCmd -Query '.show cluster databases'

. ./Scripts/New-WithClause.ps1
. ./Scripts/Format-Parameters.ps1

$createTblStub = @"
.create table (
{ColumnList}
) {WithClause}

"@

$createFuncStub = @"
.create-or-alter function {WithClause} {Name} {Parameters} {Body}

"@

$databases | ForEach-Object {
    $databaseName = $_.DatabaseName

    $dbTables = Invoke-AdxCmd -Query '.show database cslschema' -DatabaseName $databaseName

    $dbTables | ForEach-Object {
        $WithClause = New-WithClause $_.Folder $_.DocString
        $ColumnList = ($_.Schema.Split(',') | ForEach-Object {
            "    $($_.Replace(':', ': ')),"
        }) -join ([Environment]::NewLine)
        $createCmd = $createTblStub.Replace(
            '{ColumnList}', $ColumnList
        ).Replace(
            '{WithClause}', $WithClause
        )
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $tblDir = New-Item -ItemType Directory -Path "./Cluster/$clusterName/Database/$databaseName/Tables/$($_.Folder)" -Force
        $createCmd | Set-Content "$tblDir/$($_.TableName).kql"
    }

    $dbFunctions = Invoke-AdxCmd -Query '.show functions' -DatabaseName $databaseName

    $dbFunctions | ForEach-Object {
        $WithClause = New-WithClause $_.Folder $_.DocString
        $Parameters = Format-Parameters $_.Parameters
        $createCmd = $createFuncStub.Replace( 
            '{WithClause}', $WithClause
        ).Replace( 
            '{Name}', $_.Name
        ).Replace(
            '{Parameters}', $Parameters
        ).Replace(
            '{Body}', $_.Body
        )
        $_ | Add-Member -MemberType NoteProperty -Name CreateCmd -Value $createCmd
        $Directory = New-Item -ItemType Directory -Path "./Cluster/$clusterName/Database/$databaseName/Functions/$($_.Folder)" -Force
        $createCmd | Set-Content "$Directory/$($_.Name).kql"
    }
}

Pop-Location
