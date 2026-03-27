function New-GenAuthStringFromPAT {
    param(
     [string]$pat
    )

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $pat)))

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", ("Basic {0}" -f $base64AuthInfo))
    $headers.Add("Content-Type", "application/json-patch+json")
    return $headers
}
Export-ModuleMember -Function New-GenAuthStringFromPAT

function New-CurrentIterationPath {
    param(
     [string]$PAT,
     [string]$uri
    )
    $BodyIteration = @{
        '$depth' = 1
    }
    $headers = New-GenAuthStringFromPAT -pat $PAT
    $iteration_uri = "$($uri)/_apis/wit/classificationnodes/iterations"

    $result = Invoke-RestMethod -Uri $iteration_uri -Method Get -ContentType "application/json" -Headers $headers -Body $BodyIteration
    foreach ($child in $result.children) {
        $start = $child.attributes.startDate
        $end = $child.attributes.finishDate
        $today = Get-Date
        if (($today -ge $start) -and ($today -le $end)) {
            $iterPath = "$($result.name)\\$($child.name)"
            Write-Host "Iteration path is: $iterPath"
            return $iterPath
        }
    }

}
Export-ModuleMember -Function New-CurrentIterationPath

function GenPatchinJson {
    param (
    [string]$itemName,
    [string]$itemDescription,
    [string]$owner,
    [string]$parentID,
    [string]$state,
    [string]$iterationPath,
    [string]$areaPath,
    [string]$apiUrl
    )
    if ($state -ne "null") {
        $Patch = @(
            @{
                op    = "add"
                path  = "/fields/System.Title"
                value = $itemName
            },
            @{
                op    = "add"
                path  = "/fields/System.Description"
                value = $itemDescription
            },
            @{
                op    = "add"
                path  = "/fields/System.AssignedTo"
                value = $owner
            },
            @{
                op = "add"
                path = "/fields/System.AreaPath"
                value = $areaPath
            },
            @{
                op = "add"
                path = "/fields/System.IterationPath"
                value = $iterationPath
            },
            @{
                op    = "add"
                path  = "/fields/System.State"
                value = $state
            },
                   @{
                    op = "add"
                    path = "/relations/-"
                    value = @{
                        rel = "System.LinkTypes.Hierarchy-Reverse"
                        url = $apiUrl + "/$parentID"
                        }
                }
        )
    } else {

            $Patch = @(
            @{
                op    = "add"
                path  = "/fields/System.Title"
                value = $itemName
            },
            @{
                op    = "add"
                path  = "/fields/System.Description"
                value = $itemDescription
            },
            @{
                op    = "add"
                path  = "/fields/System.AssignedTo"
                value = $owner
            },
            @{
                op = "add"
                path = "/fields/System.AreaPath"
                value = $areaPath
            },
            @{
                op = "add"
                path = "/fields/System.IterationPath"
                value = $iterationPath
            },
            @{
            op = "add"
            path = "/relations/-"
            value = @{
                rel = "System.LinkTypes.Hierarchy-Reverse"
                url = $apiUrl + "/$parentID"
                }
            }
        )
    }
    $jsonPatch = $Patch | ConvertTo-Json 
    return $jsonPatch
}



function New-WorkItem {
    param (
    [string]$itemName,
    [string]$owner,
    [string]$state = "null",
    [string]$parentID,
    [string]$itemDescription = "Mangler beskrivelse",
    [string]$OrgUrl,
    [string]$itemType = "task",
    [string]$taskApiPath = "_apis/wit/workitems",
    [string]$iterationPath = "null",
    [string]$areaPath = "null",
    [string]$PAT
    
    )
    
    $uri = $OrgUrl + "/" + $taskApiPath + "/$" + $itemType + "?api-version=6.0"
    $apiurl = $OrgUrl + "/" + $taskApiPath
    $headers = New-GenAuthStringFromPAT -pat $PAT
    $body = GenPatchinJson -itemName $itemName -itemDescription $itemDescription  -parentID $parentID -apiUrl $apiurl -owner $owner -state $state -iterationPath $iterationPath -areaPath $areaPath
    $body = [System.Text.Encoding]::UTF8.GetBytes($body)
    
    try {
        $projectsResult = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body 
        #Logger det
        #Write-Host "Task oprettet. ID: $($projectsResult.id)"
        return $projectsResult.id

        } catch {
        Write-Host "Error: $_"
    }

}

Export-ModuleMember -Function New-WorkItem


Function Approve-WorkItemExists {
    param (
    [string]$pat,
    [string]$WorkItemType,
    [string]$keyword,
    [string]$baseuri
    )

    $query = "SELECT [System.Id], [System.Title] FROM workitems WHERE [System.WorkItemType] = '$WorkItemType' AND [System.Title] CONTAINS WORDS '$keyword'"

    $uri = "$baseuri/_apis/wit/wiql?api-version=6.0"

    $headerGET = New-GenAuthStringFromPAT -pat $pat

    $body = @{
        query = $query
    } |ConvertTo-Json

    $body = [System.Text.Encoding]::UTF8.GetBytes($body)

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headerGET -Method Post -Body $body -ContentType "application/json"
    }
    catch {
        $response = $_.Exception.Message
        Write-Host $response
    }
    return $response

}

Export-ModuleMember -Function Approve-WorkItemExists


function Test-OwnerIsInTeam {
    param(
        [string]$pat,
        [string]$org,
        [string]$project,
        [string]$owner,
        [string]$teamName
    )
    $headerTest = New-GenAuthStringFromPAT -pat $pat

    $teamUrl = "$org/_apis/projects/$project/teams"    

    $teamIdresponse = ((Invoke-RestMethod -Uri $teamUrl -Method Get -Headers $headerTest).Value | Where-Object {$_.name -eq $teamName}).Id

    $teamMemberUrl = "$org/_apis/projects/$project/teams/$teamIdresponse/members?api-version=6.0"

    $teamMemberresponse = ((Invoke-RestMethod -Uri $teamMemberUrl -Method Get -Headers $headerTest).Value.Identity | Where-Object {$_.displayName -eq $owner}).displayName

    if ($teamMemberresponse -eq $owner) {
        return $true
    } else {
        return $false
    }
}

Export-ModuleMember -Function Test-OwnerIsInTeam

function Get-DatesAndValidation {
    param(
        [string]$CreateMonth,
        [string]$taskName,
        [string]$itemType
    )

    function Get-FirstMonday {
        param(
            [int]$year,
            [int]$month
        )
        $date = Get-Date -Year $year -Month $month -Day 1
        while ($date.DayOfWeek -ne 'Monday') {
            $date = $date.AddDays(1)
        }
        return $date
    }

    # Setup
    $today = Get-Date
    $year = $today.Year              
    $month = $today.Month
    $shouldBeRan = $false 
    $createDate = $null

    # Finder første mandag
    $createDates = $CreateMonth -split ',' | ForEach-Object {
        $monthInt = $_.Trim() -as [int]
        Get-FirstMonday -year $year -month $monthInt
    }
    Write-Host $createDates
    # Næste kørsel
    $nextDate = ($createDates | Where-Object { $_.Date -ge $today.Date } | Sort-Object | Select-Object -First 1)

    # TaskNavn
    if ($itemType -eq "Feature") {
        $taskName += " $year"
    } else {
        $taskName += " $($year)-{0:D2}" -f $month
    }
    # Skal køres hvis det er første mandag i dag
    foreach ($date in $createDates) {
        if ($today.Date -eq $date.Date) {
            $shouldBeRan = $true
            $createDate = $date
            break
        }
    }
    if (-not $shouldBeRan) {
        if ($nextDate) {
            Write-Host "⏳ $($itemType): $taskName skal ikke oprettes før $($nextDate.ToString('dd-MM-yyyy')). Går til næste.."
        } else {
            $firstDateNextYear = $createDates | Select-Object -First 1
            $firstMonday = Get-FirstMonday -month $firstDateNextYear.Month -year $($firstDateNextYear.AddYears(1)).Year
            Write-Host "⏳ $($itemType): $taskName skal ikke oprettes før $($firstMonday.ToString('dd-MM-yyyy')). Går til næste.."
        }
    }

    return $taskName, $shouldBeRan, $createDate
}


Export-ModuleMember -Function Get-DatesAndValidation

