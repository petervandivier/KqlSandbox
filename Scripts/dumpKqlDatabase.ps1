#Requires -Modules Invoke-AdxCmd

<#
.LINK
    https://github.com/petervandivier/Invoke-AdxCmd
.LINK
    https://stackoverflow.com/questions/75315624/powershell-function-to-query-azure-data-explorer
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [string]
    $clusterUrl,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty]
    [string]
    $databaseName
)

Push-Location $PsScriptRoot

$PSDefaultParameterValues.'Invoke-AdxCmd:clusterUrl' = $clusterUrl
$PSDefaultParameterValues.'Invoke-AdxCmd:databaseName' = $databaseName

. ./New-WithClause.ps1
. ./Format-Parameters.ps1

$dbTables = Invoke-AdxCmd -Query '.show database cslschema'
$createTblStub = @"
.create-merge table (
{ColumnList}
) {WithClause}

"@

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
    $createCmd | Set-Content "../Database/Tables/$($_.TableName).kql"
}

$dbFunctions = Invoke-AdxCmd -Query '.show functions'
$createFuncStub = @"
.create-or-alter function {WithClause} {Name} {Parameters} {Body}

"@

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
    $Directory = New-Item -ItemType Directory -Path "../Database/Functions/$($_.Folder)" -Force
    $createCmd | Set-Content "$Directory/$($_.Name).kql"
}

Pop-Location
