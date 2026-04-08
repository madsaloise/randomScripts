[CmdletBinding()]
param( 
    [string]$targetRepo = "MCH_BI_QlikView"
)

#<SYSTEM VARIABLES>
$wd = $($env:System_DefaultWorkingDirectory)
$artifactDir = "$($wd)\_Build BI-Warehouse solution\BI-Warehouse-SSDT"
$modulePath = "$($artifactDir)\_Automation\Tasks\QlikPullRequestModules"
$Organisation = "$($env:System_TeamFoundationServerUri)"
$Project = "$($env:System_TeamProject)"
$token = "$($env:System_AccessToken)"
$defaultedReviewer = "$($env:RELEASE_DEPLOYMENT_REQUESTEDFORID)"

#<IMPORT MODULES>
Import-Module -Name "$($modulePath)\SQLToQVTranslations.psm1" -Force 
Import-Module -Name "$($modulePath)\ConvertStoredProcedureToQlik.psm1" -Force
Import-Module -Name "$($modulePath)\CreateQlikPullRequestFromDWH.psm1" -Force
Import-Module -Name "$($modulePath)\GetChangedFilesInWareHouse.psm1" -Force

#<SCRIPT VARIABLES>

$translations = Import-SQLToQVTranslations
$SQLFilePath = Join-Path $($artifactDir) "DWH"
$QVSPath = Join-Path $($artifactDir) "GeneratedStoredProcs"

$pseudoSchema = @("_PS_", "_KR_") -join "|"
$deployReportNamePattern = "OverallDeployReport-Deploy_to_Production_Environment-BI-Warehouse_SSDT_deployment-Release"
$deployReportsPath = "$($managementFileShare)DeploymentReports"

#<LOGIK>

#EJ ADGANG TIL DEPLOYREPORTSPATH
$latestDeployReport = Get-ChildItem -Path $deployReportsPath -Filter "$($deployReportNamePattern)*" -File |
    Select-Object *,@{Name = 'ReleaseID'; Expression = {if ($_ -match 'Release-(\d+)') { [int]$matches[1] } else { 0 }}} |`
    Sort-Object -Property @{Expression='ReleaseID';Descending=$true}, @{Expression='LastWriteTime';Descending=$true} |` #Fallback på writeTime hvis der er en re-release
    Select-Object -First 1 
$Items = Get-ChangedFilesInWareHouse -Path $latestDeployReport.FullName -nameMatch $pseudoSchema -Unique -dwhOnly


$procedureItems = $Items | Where-Object {$_.FileType -in ("SqlProcedure", "SqlView")}

Write-Host "Filer, der inkluderes er:"
Write-Host $procedureItems

if (Test-Path $QVSPath) {
    Remove-Item $QVSPath -Recurse -Force
}
New-Item -Path $QVSPath -ItemType Directory | Out-Null

foreach ($proc in $procedureItems) {
    Convert-SQLProcedureToQVS -Path $SQLFilePath `
    -File $proc `
    -OutputFilePath "$($QVSPath)\$($proc.Schema)_$($proc.Name).qvs" `
    -Translations $translations 
}

Invoke-CreateBIQlikViewPullRequest -orgUrl $Organisation -Project $Project -files $procedureItems -pat $token -targetRepo $targetRepo -QVSPath $QVSPath -reviewerID $defaultedReviewer

<# NOTER
INSERT INTO <TableName> skal være på samme linje i SQL
Oversætterfunktion skal anvendes. Primært til explorationMiljø - kan godt generere en tempTable ud fra tabeldefinitionen
BEGIN TRANSACTION/COMMIT TRANSACTION ER ET KRAV (altså ikke begin tran/commit)
Skal teste om det kan bruges med flere transactions - ellers regel om kun én

TODO: Hvis PR ikke længere findes for en branch (abandoned) eller at den er godkendt, så skal den lokale branch slettes
TODO: Skal enable at kigge i en deploymentreport
TODO: Naming af tabeller på både SQL og QLik side

Virker nu med Views og SP, Add, edit og delete (Drop, Rename Refactor og Move Schema)
#>

