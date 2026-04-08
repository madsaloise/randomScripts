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

Function Invoke-CreateBIQlikViewPullRequest {
<#
.SYNOPSIS
Creates a daily branch, commits QlikView files generated from SQL scripts, and opens a pull request with a reviewer.

.DESCRIPTION
This function automates the process of converting SQL scripts into QlikView-compatible files, creating a new branch named
for the current date, committing the changes, and generating a pull request against the source branch (default: master).
A reviewer can be specified by their Azure DevOps ID to be automatically assigned to the PR. This is useful for daily
updates where multiple SQL script changes are collected into a single branch and PR.

.PARAMETER orgUrl
URL of the Azure DevOps organization. Defaults to $env:System_TeamFoundationServerUri.

.PARAMETER project
Project name in Azure DevOps. Defaults to $env:System_TeamProject.

.PARAMETER targetRepo
Repository where the branch and changes are created. Default is "BI_QlikView".

.PARAMETER sourceBranch
Branch to base the new branch on. Default is "master".

.PARAMETER files
PSCustomObject of filenames and reasons to be included in the commit.

.PARAMETER pat
Personal Access Token for authentication. Default is taken from $env:System_AccessToken.

.PARAMETER QVSPath
Path where QlikView files should be created.

.PARAMETER reviewerID
Azure DevOps user ID of the reviewer to assign to the pull request.

.EXAMPLE
Invoke-CreateBIQlikViewPullRequest -fileNames @("script1.sql", "script2.sql") -QVSPath "C:\QlikViewFiles" -reviewerID "d6245f20-2af8-44f4-9451-8107cb2767db"

Creates a branch named "update-storedprocs-YYYYMMDD", commits the listed QlikView files, and opens a PR with the specified reviewer.

.NOTES
Author: MCH
Date: 2025-10-29
#>

    param(
        [string]$orgUrl = "$($env:System_TeamFoundationServerUri)",
        [string]$project = "$($env:System_TeamProject)",
        [string]$targetRepo = "MCH_BI_QlikView",
        [string]$sourceBranch = "master",
        [PSCustomObject]$files,
        [string]$pat = "$($env:System_AccessToken)",
        [string]$QVSPath,
        [string]$reviewerID
    )
    

    $delResp = Remove-InactiveBranches -organization $orgUrl -project $project -repositoryName $targetRepo -pat $pat

    $newBranchName = "update-storedprocs-" + (Get-Date -Format "yyyyMMdd") #"-update-storedprocs-20251028110556"

    # Opsnapper sidste commit på enten master eller newBranchName
    $branchResponse, $sourceCommitID = New-AzureBranch -Organisation $orgUrl -Project $project -targetRepo $targetRepo -newBranchName $newBranchName -pat $pat -sourceBranch $sourceBranch

    $changes = Get-AzureChangedFiles -Organisation $orgUrl -Project $project -targetRepo $targetRepo -newBranchName $newBranchName -pat $pat -files $files -QVSPath $QVSPath

    $commitResp = Invoke-AzureCommit -Organisation $orgUrl -Project $project -targetRepo $targetRepo -pat $pat -newBranchName $newBranchName -changes $changes -sourceCommitID $sourceCommitID

    $prResponse = Invoke-AzurePullRequest -Organisation $orgUrl -Project $project -pat $pat -targetRepo $targetRepo -targetBranch $sourceBranch -sourceBranch $newBranchName -reviewerID $reviewerID

    Write-Host "📝 Response for Remove-InactiveBranches:"
    Write-Host $delResp
    Write-Host "📝 Response for New-AzureBranch:"
    Write-Host $branchResponse
    Write-Host "📝 Response for Invoke-AzureCommit:"
    Write-Host $commitResp
    Write-Host "📝 Response for Invoke-AzurePullRequest:"
    Write-Host $prResponse

}
Export-ModuleMember Invoke-CreateBIQlikViewPullRequest

Function New-AzureBranch {
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv organisations-url. Default er https://devops.anklagemyndigheden.net/Analyse")]$Organisation = "https://devops.anklagemyndigheden.net/Analyse",
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv projekt-url. Default er Analyse%20og%20udvikling")]$Project = "MCH",
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv det repo, som du vil oprette en commit på.")]$targetRepo,
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv den originale branch (oftest master).")]$sourceBranch = "refs%2Fheads%2Fmaster",
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navnet på den branch, der skal oprettes")]$newBranchName,
        [string][Parameter(Mandatory=$true)]$pat = "$($env:System_AccessToken)"
    )
    $headers = New-GenAuthStringFromPAT -pat $pat

    Write-Host "⏳ New-AzureBranch: Checking if $($newBranchName) already exists..."
    $checkUrl = "$Organisation/$Project/_apis/git/repositories/$targetRepo/refs?filterContains=$newBranchName&api-version=7.1-preview"
    $existingBranch = (Invoke-RestMethod -Uri $checkUrl -Headers $headers -Method GET -ErrorAction SilentlyContinue).value

    if ($existingBranch -and $existingBranch.Count -gt 0) {
        $sourceCommitId = $existingBranch[0].objectId
        Write-Host "✅ Branch '$newBranchName' already exists. Latest commit: $sourceCommitId"
        return $existingBranch, $sourceCommitId
    }


    Write-Host "Fetching source branch info..."
    $branchUrl = "$Organisation/$project/_apis/git/repositories/$targetRepo/refs?name=$sourceBranch&api-version=7.1-preview"
    $sourceRef = (Invoke-RestMethod -Uri $branchUrl -Headers $headers -Method GET).value[0]
    $sourceCommitId = $sourceRef.objectId

    # Opretter ny branch
    $newRefBody = Get-JsonBodyForBranch -newbranchName $newBranchName -newObjectID $sourceCommitId 
    $refsUrl = "$Organisation/$project/_apis/git/repositories/$targetRepo/refs?api-version=7.1-preview"
    Write-Host "🚀 Creating branch '$newBranchName' from commit $sourceCommitId"
    try {
        $response = Invoke-RestMethod -Uri $refsUrl -Headers $headers -Method POST -Body $newRefBody -ContentType "application/json" -ErrorAction Stop
        Write-Host "✅ Branch '$newBranchName' created successfully."
    }
    catch {
        Write-Host "New-AzureBranch: ❌ Branch creation failed!"
        if ($null -ne $_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "🔍 Response body:"
            Write-Host $responseBody
        }
        else {
            Write-Host "⚠️ New-AzureBranch: No response body available."
        }
        throw
    }
    return $response, $sourceCommitId

}

Function Get-AzureChangedFiles {
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv organisations-url. Default er https://devops.anklagemyndigheden.net/Analyse")]$Organisation = "https://devops.anklagemyndigheden.net/Analyse",
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv projekt-url. Default er Analyse%20og%20udvikling")]$Project = "MCH",
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv det repo, som du vil oprette en commit på.")]$targetRepo,
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navnet på den branch, der skal merges ind")]$newBranchName,
        [string][Parameter(Mandatory=$true)]$pat = "$($env:System_AccessToken)",
        [PSCustomObject][Parameter(Mandatory=$true, HelpMessage = "Liste over filer, som der skal committes.")]$files,
        [string]$QVSPath
    )
    Write-Host "⏳ Get-AzureChangedFiles: Getting a JSON list of changes"
    $headers = New-GenAuthStringFromPAT -pat $pat
    $dwhPath = (Join-Path $(Split-Path $QVSPath -Parent) "DWH") 
    $changes = @()
    if (!(Test-Path $QVSPath)) {
        Write-Warning "Skipping missing local file: $QVSPath"
        continue
    }
    foreach ($f in $files) {
        $repoPath = "/RP/05_SQL/$($f.Schema)_$($f.Name).qvs"
        $repoPathUri = [uri]::EscapeDataString("RP\05_SQL\$($f.Schema)_$($f.Name).qvs")

        #Hvis filen er droppet på SQL skal den slettes på QV:
        if ($f.Reason -eq "Drop") {
            $deletedFileExists  = Test-FileExistsOnBranch -Organisation $Organisation -project $Project -targetRepo $targetRepo -repoPathUri $repoPathUri -newBranchName $newBranchName -headers $headers 
            if ($deletedFileExists) {
                $changes += @{
                    changeType = "delete"
                    item = @{ path = "/$repoPath" }
                }
            }
        } else {
            # Findes filen, og er der lavet ændringer?
            $newContent = Get-Content -Path "$($QVSPath)\$($f.Schema)_$($f.Name).qvs" -Raw
            $fileExists, $existingContent = Test-FileExistsOnBranch -Organisation $Organisation -project $Project -targetRepo $targetRepo -repoPathUri $repoPathUri -newBranchName $newBranchName -headers $headers -getExistingContent
            if ($fileExists) {
                if ($existingContent -eq $newContent) {
                    Write-Host "No changes detected for '$repoPath'. Skipping."
                    continue
                } else {
                    $changeType = "edit"
                }
            } else {
                $changeType = "add"
            }
            $changes += @{
                changeType = $changeType
                item = @{ path = "/$repoPath" }
                newContent = @{
                    content = $newContent
                    contentType = "rawtext"
                }
            }
        } 

        #Hvis Rename eller Moveschema slår vi op i RefactorLog og markerer dem til sletning af den gamle og indsætter den nye
        if ($f.Reason -in ('Move Schema', 'Rename Refactor')) {
            $refactorParams = switch ($f.Reason) {
                'Move Schema'   { @{ NewSchema = $f.Schema } }
                'Rename Refactor' { @{ NewName = $f.Name } }
                Default         { throw "Get-AzureChangedFiles: No reason assigned for file." }
            }

            $fileMarkedForDeletion = Get-LatestRefactorLogChange -basePath $dwhPath @refactorParams
            $deletionPath = "/RP/05_SQL/$($fileMarkedForDeletion.OriginalSchema)_$($fileMarkedForDeletion.OriginalName).qvs"
            $deletionPathUri = [uri]::EscapeDataString("RP\05_SQL\$($fileMarkedForDeletion.OriginalSchema)_$($fileMarkedForDeletion.OriginalName).qvs")
            $oldFileExists = Test-FileExistsOnBranch -Organisation $Organisation -project $Project -targetRepo $targetRepo -repoPathUri $deletionPathUri -newBranchName $newBranchName -headers $headers 
            if ($oldFileExists) {
                $changes += @{
                    changeType = "delete"
                    item = @{ path = "/$deletionPath" }
                }
            }
        }
    }
    Write-Host "🧾 Listing all change items to be committed:"
        foreach ($change in $changes) {
        Write-Host "----------------------------------------"
        Write-Host "Change Type : $($change.changeType)"
        Write-Host "File Path   : $($change.item.path)"
        Write-Host "ContentType : $($change.newContent.contentType)"
    }
    return $changes
}

Function Invoke-AzureCommit {
    [CmdletBinding()]
    param(
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv organisations-url. Default er https://devops.anklagemyndigheden.net/Analyse")]$Organisation = "https://devops.anklagemyndigheden.net/Analyse",
        [string][Parameter(Mandatory=$false, HelpMessage = "Angiv projekt-url. Default er Analyse%20og%20udvikling")]$Project = "MCH",
        [string][Parameter(Mandatory=$true)]$pat = "$($env:System_AccessToken)",
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv det repo, som du vil oprette en commit på.")]$targetRepo,
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navnet på den branch, der skal merges ind")]$newBranchName,
        [string][Parameter(Mandatory=$true, HelpMessage = "Angiv navnet på den branch, der skal merges ind")]$sourceCommitID,
        [array][Parameter(Mandatory=$true, HelpMessage = "Angiv variablen indeholdende ændringerne")]$changes
    )
    Write-Host "⏳ Invoke-AzureCommit: Creating commit.."
    $headers = New-GenAuthStringFromPAT -pat $pat
    if ($changes.Count -eq 0) {
        Write-Host "✅ No differences found. Skipping commit and PR creation."
        exit 0
    }
    Write-Host "Creating commit with $($changes.Count) changed files..."
    $pushUrl = "$Organisation/$project/_apis/git/repositories/$targetRepo/pushes?api-version=7.1-preview"

    $commitBody = Get-JsonBodyForCommit -branchName $newBranchName -sourceCommitID $sourceCommitID -changes $changes
    $commitBody = [System.Text.Encoding]::UTF8.GetBytes($commitBody)

    $commitResp = Invoke-RestMethod -Uri $pushUrl -Headers $headers -Method POST -Body $commitBody 
    Write-Host "✅Commit pushed to branch '$newBranchName'."
    return $commitResp
}


function Invoke-AzurePullRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][string]$Organisation,
        [Parameter(Mandatory = $false)][string]$Project,
        [Parameter(Mandatory = $true)][string]$pat,
        [Parameter(Mandatory = $true)][string]$targetRepo,
        [Parameter(Mandatory = $true, HelpMessage = "The branch you want to merge into (master)")][string]$targetBranch,
        [Parameter(Mandatory = $true, HelpMessage = "The branch you want to merge from (e.g. update-storedprocs-20251029)")][string]$sourceBranch,
        [Parameter(Mandatory = $true)][string]$reviewerID
    )
    Write-Host "⏳ Invoke-AzurePullRequest: Creating pull request.."
    $headers = New-GenAuthStringFromPAT -pat $pat
    $sourceRef = "refs/heads/$sourceBranch"
    $targetRef = "refs/heads/$targetBranch"

    $prQueryUrl = "$Organisation/$Project/_apis/git/repositories/$targetRepo/pullrequests?searchCriteria.sourceRefName=$sourceRef&searchCriteria.targetRefName=$targetRef&searchCriteria.status=active&api-version=7.1"
    try {
        $existingPRs = Invoke-RestMethod -Uri $prQueryUrl -Headers $headers -Method GET
        if ($existingPRs.count -gt 0) {
            Write-Host "⚠️ An active PR already exists from '$sourceRef' to '$targetRef': $($existingPRs.value[0].title)"
            return $existingPRs.value[0]
        }
    }
    catch {
        Write-Host "❌ Failed to query existing PRs."
        throw
    }
    # Json body
    $reviewers = @(@{ id = $reviewerID })
    $prBody = @{
        sourceRefName = $sourceRef
        targetRefName = $targetRef
        title         = $sourceBranch
        description   = "Automated stored procedure to QlikView updates from BI Warehouse pipeline."
        reviewers     = $reviewers
    } | ConvertTo-Json -Depth 5

    $prUrl = "$Organisation/$Project/_apis/git/repositories/$targetRepo/pullrequests?api-version=7.1"

    Write-Host "🚀 Creating Pull Request from '$sourceBranch' to '$targetBranch' ..."
    try {
        $prResponse = Invoke-RestMethod -Uri $prUrl -Headers $headers -Method POST -Body $prBody -ErrorAction Stop -ContentType application/json
        Write-Host "✅ Pull Request created successfully!"
        return $prResponse
        
    }
    catch {
        Write-Host "❌ PR failed."
        Write-Host $_.Exception.Message
        if ($null -ne $_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "🔍 PR Response:"
            Write-Host $responseBody
        }
        else {
            Write-Host "⚠️ No response body available."
        }
        throw
    }
}

function Get-JsonBodyForBranch {
    param (
    [string]$newbranchName,
    [string]$newObjectID
    )
    $value = @"
    [ { "name": "refs/heads/$newbranchName",
        "oldObjectId": "0000000000000000000000000000000000000000", 
        "newObjectId": "$newObjectID" } ]
"@
 return $value
}

function Get-JsonBodyForCommit {
    param (
        [string]$branchName,
        [string]$sourceCommitID,
        [array]$changes,
        [string]$comment = "Automated update of stored procedures from release pipeline"
    )

    $jsonChanges = foreach ($change in $changes) {
        $changeObject = @{
            changeType = $change.changeType
            item       = $change.item
        }

        # Tilføjer NewContent hvis den findes
        if ($null -ne $change.newContent) {
            $content = $change.newContent.content -replace "`r", ""
            $changeObject.newContent = @{
                content     = $content
                contentType = $change.newContent.contentType
            }
        }

        $changeObject
    }

    $bodyObject = @{
        refUpdates = @(
            @{
                name        = "refs/heads/$branchName"
                oldObjectId = $sourceCommitID
            }
        )
        commits = @(
            @{
                comment = $comment
                changes = $jsonChanges
            }
        )
    }

    $bodyJson = $bodyObject | ConvertTo-Json -Depth 10
    Write-Host "✅ Commit body created successfully. Length: $($bodyJson.Length) characters"
    return $bodyJson
}



Function Get-LatestRefactorLogChange {
    <#
    .SYNOPSIS
    Retrieves and consolidates the latest Rename and Move Schema operations from a SQL refactor log file.

    .DESCRIPTION
    The Get-LatestRefactorLogChange function parses a .refactorlog XML file generated during DACPAC deployments
    to extract "Rename Refactor" and "Move Schema" operations. It combines related operations where an object
    (e.g., a SQL table, view, or procedure) has both been renamed and moved between schemas, producing a unified
    record that shows the original and new names and schemas.

    The function returns a list of objects representing the most recent structural changes for each SQL element,
    optionally filtered by a specific new name or new schema.

    .PARAMETER basePath
    Specifies the base folder path of the DACPAC project. The function expects to find a corresponding .refactorlog file
    named after the project (e.g., "MyDatabase.refactorlog") within this path.

    .PARAMETER xmlSchema
    (Optional) Specifies the XML namespace used in the refactor log file. Defaults to
    "http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02".

    .PARAMETER NewName
    (Optional) Filters the output to include only elements whose NewName property matches the specified string or regex pattern.

    .PARAMETER NewSchema
    (Optional) Filters the output to include only elements whose NewSchema property matches the specified string or regex pattern.

    .OUTPUTS
    System.Management.Automation.PSCustomObject
    Each object includes:
    - Reason (Rename Refactor / Move Schema)
    - OriginalName
    - OriginalSchema
    - NewName
    - NewSchema
    - ChangeDateTime
    - ElementType

    .EXAMPLE
    PS C:\> Get-LatestRefactorLogChange -basePath "E:\BI-Warehouse\DWH" -NewSchema "fact"

    Returns only refactor operations that moved objects into the 'fact' schema.
    #>
    param(
    [Parameter(Mandatory = $true)][string]$basePath,
    [Parameter(Mandatory = $false)][string]$xmlSchema = "http://schemas.microsoft.com/sqlserver/dac/Serialization/2012/02",
    [Parameter(Mandatory = $false)][string]$NewName,
    [Parameter(Mandatory = $false)][string]$NewSchema
    )
    Function Split-ElementName {
        param(
        [string]$ElementName
        )
        $result = $elementName -replace '\[|\]', '' -split '\.'
        return $result
    }
    $refactorPath = "$($basePath)\$(Split-Path $basePath -Leaf).refactorlog" 
    [xml]$refactorFile = Get-Content -Path $refactorPath 
    $nameSpaceMngr = New-Object System.Xml.XmlNamespaceManager($refactorFile.NameTable)
    $nameSpaceMngr.AddNamespace("ns", $xmlSchema)

    $operations = $refactorFile.SelectNodes("//ns:Operation[@Name='Rename Refactor' or @Name='Move Schema']", $nameSpaceMngr)

    $items = foreach ($operation in $operations) {
        $properties = @{}
        foreach ($property in $operation.SelectNodes("ns:Property", $nameSpaceMngr)) {
            $properties[$property.Name] = $property.Value
        }
        [PSCustomObject]@{
            OperationName     = $operation.Name
            ChangeDateTime    = [datetime]$operation.ChangeDateTime
            ElementName       = $properties['ElementName']
            Schema            = (Split-ElementName -ElementName $properties['ElementName'])[0]
            Name              = (Split-ElementName -ElementName $properties['ElementName'])[1]
            NewName           = $properties['NewName'] -replace '\[|\]', ''
            NewSchema         = $properties['NewSchema'] 
            ElementType       = $properties['ElementType']
        }
    }
    $items = $items | Where-Object {$_.ElementType -in ("SqlView", "SqlProcedure", "SqlTable") }

    $items = $items |
        Sort-Object -Property ChangeDateTime -Descending |
        Group-Object -Property OperationName, ElementName |
        ForEach-Object { $_.Group[0] } 
    
    $combined = @()

    $renames = $items | Where-Object { $_.OperationName -eq 'Rename Refactor' }
    $moves   = $items | Where-Object { $_.OperationName -eq 'Move Schema' }

    foreach ($rename in $renames) {
        # Prøver at lede efter steder, hvor rename matcher et move
        $match = $moves | Where-Object {
            $_.Name -eq $rename.NewName -and $_.Schema -eq $rename.Schema
        } | Sort-Object ChangeDateTime -Descending | Select-Object -First 1

        if ($match) {
            $combined += [PSCustomObject]@{
                Reason         = $rename.OperationName
                OriginalName   = $rename.Name
                OriginalSchema = $rename.Schema
                NewName        = $rename.NewName
                NewSchema      = $match.NewSchema
                ChangeDateTime = ($rename.ChangeDateTime, $match.ChangeDateTime | Measure-Object -Maximum).Maximum
                ElementType    = $rename.ElementType
            }
        }
        else {
            $combined += [PSCustomObject]@{
                Reason         = $rename.OperationName
                OriginalName   = $rename.Name
                OriginalSchema = $rename.Schema
                NewName        = $rename.NewName
                NewSchema      = $rename.NewSchema
                ChangeDateTime = $rename.ChangeDateTime
                ElementType    = $rename.ElementType
            }
        }
    }

    # Tilføjer de der kun har rykket schema
    $renameNewNames = $renames.NewName
    $onlyMoves = $moves | Where-Object { $_.Name -notin $renameNewNames }

    foreach ($move in $onlyMoves) {
        $combined += [PSCustomObject]@{
            Reason         = $move.OperationName
            OriginalName   = $move.Name
            OriginalSchema = $move.Schema
            NewName        = $move.NewName
            NewSchema      = $move.NewSchema
            ChangeDateTime = $move.ChangeDateTime
            ElementType    = $move.ElementType
        }
    }

    $items = $combined | Sort-Object ChangeDateTime -Descending

    if ($PSBoundParameters.ContainsKey('NewName')) {
        $items = $items | Where-Object { $_.NewName -match $NewName }
    }
    if ($PSBoundParameters.ContainsKey('NewSchema')) {
        $items = $items | Where-Object { $_.NewSchema -match $NewSchema }
    }

    Return $items
}



Function Test-FileExistsOnBranch {
    param(
       [Parameter(Mandatory=$true)][string]$Organisation,
       [Parameter(Mandatory=$true)][string]$project,
       [Parameter(Mandatory=$true)][string]$targetRepo,
       [Parameter(Mandatory=$true)][string]$repoPathUri,
       [Parameter(Mandatory=$true)][string]$newBranchName,
       [Parameter(Mandatory=$true)][hashtable]$headers,
       [Parameter(Mandatory=$false)][switch]$getExistingContent

    )
    $fileUrl = "$Organisation/$project/_apis/git/repositories/$targetRepo/items?path=%2F$repoPathUri&versionDescriptor.version=$newBranchName&includeContent=true&api-version=7.1-preview"
    $fileExists = $false
    $existingContent = ""
    try {
        $existingResponse = Invoke-RestMethod -Uri $fileUrl -Headers $headers -Method GET -ErrorAction Stop
        $fileExists = $true
        $existingContent = $existingResponse.content
        
    } catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 404) {
            $fileExists = $false
        } else {
            throw "Test-FileExistsOnBranch: $($_)"
        }
    } 
    if ($getExistingContent) { 
        return $fileExists, $existingContent 
    } else {
        return $fileExists
    } 
}

function Remove-InactiveBranches {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $organization,

        [Parameter(Mandatory=$true)]
        [string] $project,

        [Parameter(Mandatory=$true)]
        [string] $repositoryName,

        [Parameter(Mandatory=$true)]
        [string] $pat, 

        [Parameter(Mandatory=$false)]
        [string] $branchName = "update-storedprocs"
    )
    Write-Host "⏳ Remove-InactiveBranches: Checking for inactive branches.."
    
    $headers = New-GenAuthStringFromPAT -pat $pat
    $refsUrl = "$Organisation/$Project/_apis/git/repositories/$repositoryName/refs?filterContains=$($branchName)&api-version=7.1-preview"
    $refsResp = Invoke-RestMethod -Uri $refsUrl -Headers $headers -Method Get
    $branches = $refsResp.value

    foreach ($branch in $branches) {
        $refName = $branch.name
        $prUrl = "$Organisation/$Project/_apis/git/repositories/$repositoryName/pullrequests?searchCriteria.sourceRefName=$([uri]::EscapeDataString($refName))&searchCriteria.status=active&api-version=7.1-preview"
        $prResp = Invoke-RestMethod -Uri $prUrl -Headers $headers -Method Get
        if ($prResp.count -eq 0) {
            Write-Host "🗑️ No active PR found for branch '$refName'. Deleting branch..."
            $RefBody = Get-JsonBodyForBranchDeletion -branchName $refName -oldObjectId $branch.objectId
            $deleteUrl = "$Organisation/$Project/_apis/git/repositories/$repositoryName/refs?api-version=7.1-preview"
            $delResp = Invoke-RestMethod -Uri $deleteUrl -Headers $headers -Method Post -Body $RefBody -ContentType "application/json"
            Write-Host "Deleted branch '$refName'"
            return $delResp
        }
    }
}
function Get-JsonBodyForBranchDeletion {
    param (
    [string]$branchName,
    [string]$oldObjectID
    )
    $value = @"
    [ { "name": "$branchName",
        "oldObjectId": "$oldObjectID", 
        "newObjectId": "0000000000000000000000000000000000000000"} ]
"@
 return $value
}

