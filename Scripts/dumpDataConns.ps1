
<#
.SYNOPSIS
    Dumps cold-start DB & Data Connection config for every DB in a cluster
#>

Push-Location $PsScriptRoot/..

$ClusterName = 'testnewkustocluster'
$ResourceGroupName = 'testrg'

$ClusterSplat = @{
    ClusterName = $ClusterName
    ResourceGroupName = $ResourceGroupName
}

# https://learn.microsoft.com/en-us/powershell/module/az.kusto/new-azkustodatabase
$NewDbProps = @(
    @{Name='Name';              Expression={$_.Name.Split('/')[1]}}
    @{Name='ResourceGroupName'; Expression={"$ResourceGroupName"}}
    @{Name='ClusterName';       Expression={"$ClusterName"}}
    @{Name='Kind';              Expression={$_.Kind.ToString()}}
    'Location'
    @{Name='HotCachePeriod';    Expression={$_.HotCachePeriod.ToString()}}
    @{Name='SoftDeletePeriod';  Expression={$_.SoftDeletePeriod.ToString()}}
)

# https://learn.microsoft.com/en-us/powershell/module/az.kusto/new-azkustodataconnection
# EventSystemProperty at least requires complex handling which I don't want to write
# since it's unused anyhow so I'm just excluding it for the time being
# also skipping SubscriptionId at this time
$NewDataConnProps = @(
    @{Name='ClusterName';        Expression={"$ClusterName"}}
    @{Name='DatabaseName';       Expression={"$DatabaseName"}}
    @{Name='Name';               Expression={$_.Name.Split('/')[2]}}
    @{Name='ResourceGroupName';  Expression={"$ResourceGroupName"}}
    @{Name='ConsumerGroup';      Expression={$_.ConsumerGroup.ToString()}}
    'EventHubResourceId'
    @{Name='Kind';               Expression={$_.Kind.ToString()}}
    'Location'
    @{Name='DataFormat';         Expression={$_.DataFormat.ToString()}}
    @{Name='Compression';        Expression={$_.Compression.ToString()}}
    'MappingRuleName'
    'TableName'
)

Get-AzKustoDatabase @ClusterSplat | ForEach-Object {
    $DatabaseName = $_.Name.Split('/')[1]

    # Push-Location "Cluster/$ClusterName/Database/$DatabaseName"
    Push-Location "Database/$DatabaseName"

    $_ | Select-Object $NewDbProps | ConvertTo-Json | Set-Content "${DatabaseName}.json"

    New-Item -ItemType Directory -Path DataConnections -Force | Out-Null

    Get-AzKustoDataConnection @ClusterSplat -DatabaseName $DatabaseName | ForEach-Object { 
        $_ | 
            Select-Object $NewDataConnProps |
            ConvertTo-Json -Depth 10 | 
            Set-Content "DataConnections/$($_.Name.Split('/')[2]).json" 
    }

    Pop-Location
}

Pop-Location
