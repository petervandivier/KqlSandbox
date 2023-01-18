<#
.SYNOPSIS
    Given a local instance of the MicrosoftDocs/dataexplorer-docs repo, extract the functions 
    from markdown files in that repo to this directory.

.LINK
    https://github.com/MicrosoftDocs/dataexplorer-docs/tree/main/data-explorer/kusto/functions-library
#>

Param(
    [Parameter()]
    [ValidateScript({Test-Path "$_/data-explorer/kusto/functions-library" -PathType directory})]
    [string]
    $repoDir = "${HOME}/GitHub/dataexplorer-docs",

    [Parameter()]
    [ValidateScript({Test-Path $_ -PathType directory})]
    [string]
    $outDir = "$PsScriptRoot/Functions"
)

Push-Location "${repoDir}/data-explorer/kusto/functions-library"

function ConvertTo-KustoDocsFileName {
<#
.SYNOPSIS
    Changes function identifier to corresponding docs file name

.PARAMETER functionName
    Underscores only, may include trailing parens. Exactly as seen on docs page
#>
    Param(
        [string]
        $functionName
    )
    return "$($functionName.Replace('_','-').Replace('()','')).md"
}
function Get-KustoFunctionDefinitionFromDocsSource {
<#
.SYNOPSIS
    Given docs mardown file name, get the source code text from the markdown content. 
.DESCRIPTION
    Syntax variance in the Microsoft docs necessitates the $startAtLine / $stopAtLine 
    variables to be calculated as they are below rather than a tidier .IndexOf() invocation.
.OUTPUTS
    [string[]]
#>
    Param(
        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]
        $fileName
    )
    $docsFileContent = Get-Content $fileName
    $startAtLine = ([Linq.Enumerable]::Range(0, $docsFileContent.Count).Where({ param($i) $docsFileContent[$i] -match '^.create' }) | Measure-Object -Minimum).Minimum
    $stopAtLine = -3 + ([Linq.Enumerable]::Range(0, $docsFileContent.Count).Where({ param($i) $docsFileContent[$i] -match '^### Usage' }) | Measure-Object -Minimum).Minimum
    $docsFileContent[$startAtLine .. $stopAtLine]
}

function New-KustoDocsFunctionFile {
<#
.SYNOPSIS
    Given a function name, output the definition as found in the docs to an appropriate folder. 
#>
    param (
        [string]
        $functionName
    )
    $fileName = ConvertTo-KustoDocsFileName $functionName
    $functionDefinition = (Get-KustoFunctionDefinitionFromDocsSource $fileName) -join "`n"
    $null = $functionDefinition -match 'folder\s=\s"(?<folder>.+?)"'
    $folder = $Matches.folder
    $destFolder = New-Item "${outDir}/${folder}" -ItemType Directory -Force 
    $functionDefinition | Set-Content "${destFolder}/${functionName}.csl" -Force
}


$generalFunctions = @"
Function Name	Description
get_packages_version_fl()	Returns version information of the Python engine and the specified packages.
"@ | ConvertFrom-Csv -Delimiter "`t"


$machineLearningFunctions = @"
Function Name	Description
kmeans_fl()	Clusterize using the k-means algorithm.
predict_fl()	Predict using an existing trained machine learning model.
predict_onnx_fl()	Predict using an existing trained machine learning model in ONNX format.
"@ | ConvertFrom-Csv -Delimiter "`t"


$plotlyFunctions = @"
Function Name	Description
plotly_anomaly_fl()	Render anomaly chart using a Plotly template.
plotly_scatter3d_fl()	Render 3D scatter chart using a Plotly template.
"@ | ConvertFrom-Csv -Delimiter "`t"

$promQlFunctions = @"
Function Name	Description
series_metric_fl()	Select and retrieve time series stored with the Prometheus data model.
series_rate_fl()	Calculate the average rate of counter metric increase per second.
"@ | ConvertFrom-Csv -Delimiter "`t"

$seriesFunctions = @"
Function Name	Description
quantize_fl()	Quantize metric columns.
series_dbl_exp_smoothing_fl()	Apply a double exponential smoothing filter on series.
series_dot_product_fl()	Calculate the dot product of two numerical vectors.
series_downsample_fl()	Downsample time series by an integer factor.
series_exp_smoothing_fl()	Apply a basic exponential smoothing filter on series.
series_fit_lowess_fl()	Fit a local polynomial to series using LOWESS method.
series_fit_poly_fl()	Fit a polynomial to series using regression analysis.
series_fbprophet_forecast_fl()	Forecast time series values using the Prophet algorithm.
series_lag_fl()	Apply a lag filter on series.
series_moving_avg_fl()	Apply a moving average filter on series.
series_mv_ee_anomalies_fl()	Multivariate Anomaly Detection for series using elliptical envelope model.
series_mv_if_anomalies_fl()	Multivariate Anomaly Detection for series using isolation forest model.
series_mv_oc_anomalies_fl()	Multivariate Anomaly Detection for series using one class SVM model.
series_rolling_fl()	Apply a rolling aggregation function on series.
series_shapes_fl()	Detects positive/negative trend or jump in series.
series_uv_anomalies_fl()	Detect anomalies in time series using the Univariate Anomaly Detection Cognitive Service API.
series_uv_change_points_fl()	Detect change points in time series using the Univariate Anomaly Detection Cognitive Service API.
time_weighted_avg_fl()	Calculates the time weighted average of a metric.
time_window_rolling_avg_fl()	Calculates the rolling average of a metric over a constant duration time window.
"@ | ConvertFrom-Csv -Delimiter "`t"

# corrected docs typo `levene_test_fl()n` → `levene_test_fl()`
$statsFunctions = @"
Function Name	Description
bartlett_test_fl()	Perform the Bartlett test.
binomial_test_fl()	Perform the binomial test.
comb_fl()	Calculate C(n, k), the number of combinations for selection of k items out of n.
factorial_fl()	Calculate n!, the factorial of n.
ks_test_fl()	Perform a Kolmogorov Smirnov test.
levene_test_fl()	Perform a Levene test.
normality_test_fl()	Performs the Normality Test.
mann_whitney_u_test_fl()	Perform a Mann-Whitney U Test.
pair_probabilities_fl()	Calculate various probabilities and related metrics for a pair of categorical variables.
pairwise_dist_fl()	Calculate pairwise distances between entities based on multiple nominal and numerical variables.
percentiles_linear_fl()	Calculate percentiles using linear interpolation between closest ranks
perm_fl()	Calculate P(n, k), the number of permutations for selection of k items out of n.
two_sample_t_test_fl()	Perform the two sample t-test.
wilcoxon_test_fl()	Perform the Wilcoxon Test.
"@ | ConvertFrom-Csv -Delimiter "`t"

foreach (
    $collection in @(
        $generalFunctions
        $machineLearningFunctions
        $plotlyFunctions
        $promQlFunctions
        $seriesFunctions
        $statsFunctions 
    )
) {
    $collection | ForEach-Object {
        $functionName = ($_.'Function Name').Replace('()','')
        New-KustoDocsFunctionFile $functionName
    }
}

Pop-Location
