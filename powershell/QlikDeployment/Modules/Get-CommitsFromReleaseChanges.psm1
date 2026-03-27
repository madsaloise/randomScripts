Function Get-ReleaseIDByPipeline {
    param(
    [int][Parameter(Mandatory=$false, HelpMessage = "Angiv hvor mange iterationer tilbage, som releasen er. Default er 0 for seneste iteration")]$valueID = 0,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv organisations-url.")]$Organisation,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv projekt-url.")]$Project,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv personal access token.")]$token,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navn på Release Pipeline.")]$pipelineName,
    [int][Parameter(Mandatory=$true)]$pipelineID
    )
    $pat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($token)"))
    $url="$($Organisation)/$($Project)/_apis/release/deployments?definitionId=$($pipelineID)&deploymentStatus=succeeded&definitionEnvironmentId=releasedefinitionenvironmentid&api-version=6.0"
    $response = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Basic $pat"} -Method Get -ContentType application/json
    
    $responseValue = $response.Value | Where-Object { ($_.releaseDefinition.name -eq $pipelineName) -and ($_.releaseEnvironment.name -eq "Deploy to Production")}
    
    $lastreleaseid = $responseValue[$valueID].release.id
    Return $lastreleaseid
}

Function Get-ReleaseChanges {
    param(
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv organisations-url.")]$Organisation,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv projekt-url.")]$Project,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv personal access token.")]$token,
    [int][Parameter(Mandatory=$true, HelpMessage = "Angiv nummeret på aktuel release")]$currentReleaseID,
    [int][Parameter(Mandatory=$true, HelpMessage = "Angiv nummeret på sidste release")]$lastreleaseID
    
    )
    $pat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($token)"))
    $url ="$($Organisation)/$($Project)/_apis/Release/releases/$($currentReleaseID)/changes?baseReleaseId=$($lastreleaseID)&%24top=2500&api-version=7.1-preview.1"
    #$url ="$($Organisation)/$($Project)/_apis/Release/releases/$($currentReleaseID)/changes?baseReleaseId=117&%24top=2500&api-version=7.1-preview.1"
    #Filter til url: &artifactAlias=Artifacts Alias name

    $response = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Basic $pat"} -Method Get -ContentType application/json

    return $response
}


Function Get-DocumentListFromChanges {
    param(
    [array]$list
    )
    $tmpContainer = @()
    $finalList = @()
    foreach ($item in $list) {
        $filePath = $item.FilePath
        #Hiver filnavne ud
        $filnavn = split-path -path $filePath -Leaf
        $hierarki = Split-Path -Path (split-path -path $filePath -Parent) -Leaf
        $spor = Split-Path -Path (Split-Path -Path (split-path -path $filePath -Parent) -Parent) -Leaf
        $filnavn = $filnavn -replace "-prj", ".qvw"
        $tmpObject = [pscustomobject]@{
            Spor    = $spor
            Hierarki  = $hierarki
            FilNavn = $filNavn
        }
        $tmpContainer += $tmpObject
        $finalList += $tmpContainer

    }
    Return $finalList 

}

Function Get-CommitsFromReleaseChanges {
    param(
    [int][Parameter(Mandatory=$false, HelpMessage = "Angiv hvor mange iterationer tilbage, som releasen er. Default er 0 for seneste iteration")]$valueID = 0,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv organisations-url.")]$Organisation,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv projekt-navn.")]$Project,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv repository-navn.")]$RepoId,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv personal access token.")]$token,
    [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navn på Release Pipeline.")]$pipelineName,
    [int][Parameter(Mandatory=$true, HelpMessage = "Angiv ID på nuværende release.")]$currentReleaseID,
    [int][Parameter(Mandatory=$true, HelpMessage = "Angiv ID på selve pipelinen.")]$pipelineID,
    [switch]$GetDocumentList
    )
    $list = @()
    $pat = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($token)"))
    $lastreleaseID = Get-ReleaseIDByPipeline -valueID $valueID -Organisation  $Organisation -Project $Project -token $token -pipelineName $pipelineName -pipelineID $pipelineID
    $releaseChanges = Get-ReleaseChanges -Organisation $Organisation -Project $Project -token $token -lastreleaseID $lastreleaseID -currentReleaseID $currentReleaseID
    Foreach ($commitid in $releaseChanges.value.id){
        $url = "$($Organisation)/$($Project)/_apis/git/repositories/$($RepoId)/commits/$($commitid)/changes?api-version=7.0"
        $response = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Basic $pat"} -Method Get -ContentType application/json
        Foreach ($changefile in $response.changes){
            If ($changefile.item.path.EndsWith("-prj") -and -not $changefile.item.path.contains("TilsynDimensionerJobs")) {
                $tmpObject = [pscustomobject]@{
                        FilePath    = $changefile.item.path
                        CommitID  = $changefile.item.commitId
                        ChangeType  = $changefile.changeType
                }
                $list += $tmpObject
            }
        }
    }
    #Manipulerer liste til at returnere den laveste værdi i hvert spor   
    if ($GetDocumentList.IsPresent) {
        $list = $list | Select-Object -Property * -ExcludeProperty "CommitID" -Unique
        $finalList = Get-DocumentListFromChanges -list $list 
        return $finalList 
    } 
    return $list
}
Export-ModuleMember -Function Get-CommitsFromReleaseChanges



function Start-QVWAndMonitorProcess {
    param (
        [string]$fileName,
        [string]$filePath, 
        [int][Parameter(Mandatory=$false)]$iterationsFallback = 30
    )
    # Starter Proces
    $process = Start-Process -FilePath "C:\Program Files\QlikView\Qv.exe" -ArgumentList "/r", "`"$($filePath)`""  -PassThru 
    Start-Sleep 5
    #Sætter counter til lave ressourcer og defaulter monitor switch til $true
    $lowResourceCount = 0
    $monitoring = $true
    $CPU = 0
    while ($monitoring) {
        # Hvis processen er lukket
        if ($process.HasExited) {
            Write-Host "Processen for $($fileName) er afsluttet. Tjekker efter nye filer..." 
            $monitoring = $false
            continue
        }
        $changeCPU = $process.CPU - $CPU
        # Tester om den forbruger CPU (Mine tests gav at den voksede med højest 0,2 hver gang, hvis den gik i stå.)
        if (($changeCPU) -lt 1) {
            $lowResourceCount++
            $msg = "Ressourceforbruget for $($fileName) er lavt. (Samlet CPU-tid: $($process.CPU), Stigning i CPU-tid: $($changeCPU))"
            if ($lowResourceCount -ge $iterationsFallback) {
                $msg = "Ressourceforbruget for $($fileName) er lavt over tre tjeks. Processen stoppes."
                Stop-Process -Id $process.Id
                $monitoring = $false
            }
        } else {
            $lowResourceCount = 0
            $msg = "Processen for $($fileName) bruger: (Samlet CPU-tid: $($process.CPU), Stigning i CPU-tid: $($changeCPU))"
        }
        $CPU = $process.CPU
        $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")     
        Write-Host "$($timestamp) --- $($msg)"
        Start-Sleep -Seconds 10
    }
    #Releaser process ved slut..
    $process = $null

}

Export-ModuleMember -Function Start-QVWAndMonitorProcess

