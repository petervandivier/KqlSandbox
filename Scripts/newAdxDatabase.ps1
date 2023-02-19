
<#
.LINK
    https://learn.microsoft.com/en-us/powershell/module/az.kusto/new-azkustodatabase
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $DatabaseName
)

Push-Location $PsScriptRoot/..

$NewDatabase = Get-Content "Config/${DatabaseName}.jsonc" | ConvertFrom-Json -AsHashtable

if($NewDatabase){
    New-AzKustoDatabase @NewDatabase
}

Pop-Location
