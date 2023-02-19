
<#
.LINK
    https://learn.microsoft.com/en-us/powershell/module/az.kusto/remove-azkustodatabase
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $DatabaseName
)

Push-Location $PsScriptRoot/..

$DropDatabase = Get-Content "Config/${DatabaseName}.jsonc" | ConvertFrom-Json -AsHashtable 

$DropDatabase.Remove('Kind')
$DropDatabase.Remove('Location')

if($DropDatabase){
    Remove-AzKustoDatabase @DropDatabase
}

Pop-Location
