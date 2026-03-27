$Organisation = "$(System.TeamFoundationServerUri)"
$Project = "$(System.TeamProject)"
$token = "$(System.AccessToken)"
$RepoId = "NameOfRepo" 
$pipelineName = "$(Release.DefinitionName)"
$pipelineId = $(Release.DefinitionID)
$currentReleaseID = $(Release.ReleaseId)
Write-Host $pipelineId

Write-Host 'FETCH Licens'
&"C:\Program Files\QlikView\Qv.exe" /r "qvp://QlikServer.ServerName.net/testaftask .qvw"   
Start-Sleep 10
Write-Host "Licens Hentet"


#Import
Import-Module -Name "$(System.DefaultWorkingDirectory)/_BI-QlikView/BI-QlikView-ArtifactFiles/_Automation/Tasks/Modules/Get-CommitsFromReleaseChanges.psm1"
Write-Host "Finder commits.."
$commitInfo = Get-CommitsFromReleaseChanges -GetDocumentList -Organisation $Organisation -Project $Project -RepoId $RepoId -token $token -pipelineName $pipelineName -currentReleaseID $currentReleaseID -pipelineID $pipelineId 
$commitInfo = $commitInfo | Select-Object -Property * -Unique | Sort-Object {$_.Spor, $_.Hierarki}  

Write-Host "Åbner og lukker filer.."
foreach ($documentName in $commitInfo.filNavn) { 
    Write-Host "Reloader $($documentName).." 
    try { 
        $file = Get-ChildItem -Path "$(DeployFilePath)" -Filter $documentName -Recurse 
        Start-QVWAndMonitorProcess -fileName $file.Name -filePath $file.FullName -iterationsFallback 3
    } catch {
        Write-Host "Qlikview (.qvw) filen $($documentName) kan ikke findes."
        Write-Host $_
        Exit 1
    }
    
}