function Format-Parameters {
    Param(
        [string]$Parameters
    )
    if($Parameters -eq '()'){
        return '()'
    }
    $Parameters = $Parameters -replace "^\(", "(`n    " 
    $Parameters = $Parameters.Replace(",", ",`n    ")
    $Parameters = $Parameters.Replace(":", ": ")
    $Parameters = $Parameters -replace "\)$", "`n)"
    $Parameters = $Parameters -replace "\n(\s+)\n", "`n"
    return $Parameters 
}
