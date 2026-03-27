param(
    [string]$teamName
)
<#
I JSON sættes UpdateFrequency = 1, hvis månedlig, =3 hvis kvartal osv. De genereres altid i starten af måneden.
Hvis CreateDate er udfyldt, så anvendes UpdateFrequency ikke. Denne dato er tiltænkt årlige oprettelser såsom Featureoprettelse og datatjek osv.
#>
Import-Module -Name "$($env:System_DefaultWorkingDirectory)\_BI-Automation-Scheduler\BI-Automation-Scheduler-ArtifactFiles\Udvikler\AzureDevops\BIRetentionReminders\Modules\CreateDevopsTasks.psm1" -Force

$Organisation = "$($env:System_TeamFoundationServerUri)"
$Project = "$($env:System_TeamProject)"
$token = "$($env:System_AccessToken)"
$devopsAddress = "$Organisation/$Project"




#Indlæs fil
$jsonFilePath = "$($env:System_DefaultWorkingDirectory)\_BI-Automation-Scheduler\BI-Automation-Scheduler-ArtifactFiles\Udvikler\AzureDevops\BIRetentionReminders\Data\TaskData.json"
$encoding = [System.Text.Encoding]::UTF8  
$jsonContent = [System.IO.File]::ReadAllText($jsonFilePath, $encoding)
$json = $jsonContent | ConvertFrom-Json

#Finder nuværende sprint
$iterationPath = New-CurrentIterationPath -pat $token -uri $devopsAddress

foreach ($feature in $json.Features) {
    #!# Test om owner er i systemet. 
    $owner = $feature.Owner
    if ((Test-OwnerIsInTeam -pat $token -org $Organisation -project $Project -owner $owner -teamName $teamName) -eq $false) {
        Write-Host "❌ $owner er sat som ejer på $($feature.Name), men $owner findes ikke i devops."
        Continue
    }
    #!# Navngivning til feature og tjek om den skal laves i denne uge.
    $feature | Add-Member -NotePropertyName 'ShouldBeRan' -NotePropertyValue $false
    $feature | Add-Member -NotePropertyName 'CreateDate' -NotePropertyValue $null
    $feature.Name, $feature.shouldBeRan, $feature.CreateDate = Get-DatesAndValidation -CreateMonth $feature.CreateMonth -taskName $feature.Name -itemType "Feature"
    $areaPath = $feature.AreaPath
    #!# Tester om feature allerede findes. Ellers oprettes den. Feature oprettes altid i starten af året
    $featureExists = Approve-WorkItemExists -pat $token -WorkItemType "Feature" -keyword $feature.Name -baseuri $devopsAddress
    if ($featureExists.workItems.Count -eq 0) {
            Write-Host "Feature: $($feature.Name) findes ikke i forvejen. Opretter.."
            $featureID = New-WorkItem -itemName $feature.Name -parentID $feature.ParentId -itemDescription $feature.Description -itemType "Feature" -PAT  $token  -OrgUrl $devopsAddress -owner $owner -state $feature.State -iterationPath $iterationPath -areaPath $areaPath
    } else {
        Write-Host "Leder efter feature: $($feature.Name)"
        $featureID = $featureExists.workItems.id
    }
    #!# Hvis featuren ikke kan findes, så afsluttes
    if (-not $featureID) { 
        Write-host "❌ FeatureID kan ikke findes for $($feature.Name). Springer over.."
        Continue
    } else { Write-Host "✅ FeatureID er: $featureID"}
    #!# Feature oprettet. Går i gang med PBI
    foreach ($pbi in $feature.ProductBacklogItems) {

        if ($pbi.Owner) {
            if ((Test-OwnerIsInTeam -pat $token -org $Organisation -project $Project -owner $pbi.Owner -teamName $teamName) -eq $false) {
                Write-Host "❌ $($pbi.Owner) er sat som ejer på $($pbi.Name), men $($pbi.Owner) findes ikke i devops."
                Continue
            }
            $owner = $pbi.Owner
        } else {
            $owner = $feature.Owner
        }
        if ($pbi.AreaPath) {
            $areaPath = $pbi.AreaPath
        } else {
            $areaPath = $feature.AreaPath
        }
        #!# Sætter dato og PBI navn
        $pbi | Add-Member -NotePropertyName 'ShouldBeRan' -NotePropertyValue $false
        $pbi | Add-Member -NotePropertyName 'CreateDate' -NotePropertyValue $null
        $pbi.Name, $pbi.shouldBeRan, $pbi.CreateDate = Get-DatesAndValidation -CreateMonth $pbi.CreateMonth -taskName $pbi.Name -itemType "PBI"
        if ($pbi.shouldBeRan -eq $true) {
            Write-Host "✅ PBI oprettes: $($pbi.Name)"
            $PBIid = New-WorkItem -itemName $pbi.Name -parentID $featureID -OrgUrl $devopsAddress -itemDescription $pbi.Description -itemType "Product%20Backlog%20Item" -PAT  $token -owner $owner -state $pbi.State -iterationPath $iterationPath -areaPath $areaPath
            Write-Host "...task oprettes for $($pbi.Name)"
            foreach ($task in $pbi.Tasks) {
            #!# Tasknavn nedarves af PBI
                $task.Name += " $($pbi.CreateDate.ToShortDateString())"
                Write-Host "✅ Task oprettes: $($task.Name)"
                $taskID = New-WorkItem -itemName $task.Name -parentID $PBIid -OrgUrl $devopsAddress -itemDescription $task.Description -itemType "task" -PAT  $token -owner $owner -iterationPath $iterationPath -areaPath $areaPath
            }
            Write-Host "--------------------------"
        }
    }
}