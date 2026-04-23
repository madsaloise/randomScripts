$commonParams = @(
    [System.Management.Automation.Cmdlet]::CommonParameters +
    [System.Management.Automation.Cmdlet]::OptionalCommonParameters
)

$__varsBefore = Get-Variable | Select-Object -ExpandProperty Name
$__envBefore     = Get-ChildItem Env: | Select-Object -ExpandProperty Name

<# INSERT VARIABLES HERE #>
#example
$ThisIsAVariable = "This variable is made in the profile!"
$Env:ThisIsAnEnvVariable = "This env variable is made in the profile!"

#used for other scripts, so they can be used without hardcoding them in the scripts, and they can be easily updated here if needed
$qmcHostTest = ""
$qmcHostProd = ""
$accessPointTest = ""
$accessPointProd = ""

$senseHubTest = ""
$senseTestAppID = ""

$dwhTest = ""
$dwhStaging = ""
$dwhProd = ""
$schedulerUri = ""

$managementFileShare = ""
$qlikTestFileShare = ""
$qlikProdFileShare = ""

$emailMCH = ""
$emailQlikView = ""
$emailAnalyse = ""
$emailIndkoeb = ""
$env:System_TeamFoundationServerUri = ""
$env:System_TeamProject            = [System.Uri]::EscapeDataString("")
$pat = $env:System_AccessToken     = ""
$env:System_DefaultWorkingDirectory = (Get-Location).Path

<# VARIABLES END#>

$__varsAfter = Get-Variable
$__envAfter  = Get-ChildItem Env:

$__newVars = $__varsAfter | Where-Object {
    $_.Name -notin $__varsBefore
}

$__newEnv = $__envAfter | Where-Object {
    $_.Name -notin $__envBefore
}

#henter moduler
$modulePath = "E:\MchWork-1\pwshProfile"

if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
        Write-Host "Importing module: $($_.Name)" -ForegroundColor Cyan
        
        $module = Import-Module $_.FullName -Force -PassThru

        $functions = $module.ExportedFunctions.Keys

        if ($functions.Count -gt 0) {
            Write-Host "  Exported functions:" -ForegroundColor Yellow
            foreach ($func in $functions) {
                Write-Host "    - $func" -ForegroundColor Green
                $command = Get-Command $func -Module $module.Name
                if ($command.Parameters.Count -gt 0) {
                    foreach ($param in $command.Parameters.Values) {
                        if ($param.Name -in $commonParams) {
                            continue
                        }
                        $mandatory = if ($param.Attributes.Mandatory) { "[Required]" } else { "" }
                        $type = $param.ParameterType.Name
                        Write-Host ("        * {0} ({1}) {2}" -f $param.Name, $type, $mandatory) -ForegroundColor DarkCyan
                    }
                }
            }
        } else {
            Write-Host "  (No exported functions)" -ForegroundColor DarkGray
        }
    }
}

Write-Host "`n=== Variables Loaded ===" -ForegroundColor Cyan

$__newVars |
Where-Object { $_.Name -notmatch "^(__|PS|PWD|HOME)" } |
Sort-Object Name |
ForEach-Object {
   $value = if ($_.Name -eq "pat") { "hidden" } else { $_.Value }
    Write-Host ("{0,-20}: {1}" -f $_.Name, $value)
}
Write-Host "Variables in env:" -ForegroundColor Cyan
$__newEnv |
Sort-Object Name |
ForEach-Object {
    $value = if ($_.Name -match "System_AccessToken") { "hidden" } else { $_.Value }
    Write-Host ("{0,-20}: {1}" -f $_.Name, $value)
}