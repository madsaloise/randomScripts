[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$MailTo,
    [Parameter(Mandatory=$false)]
    [string]$date = (Get-Date).AddDays(-7).ToString("dd-MM-yyyy")
)

$SMTPServer = "smtp.servername.dk" #Replace mail logic with Send-Outlookmail if needed.

$RepoPath = "$($env:System_DefaultWorkingDirectory)/_RepoName"
$database = "DWH" #Single database in project, rewrite refactorlogpath if checking multiple
$RefactorLogPath = "$($RepoPath)/$($database)/$($database).refactorlog"

function Get-DanishDateFormat {
    param([string]$DateString)
    
    if ([string]::IsNullOrWhiteSpace($DateString)) {
        return $null
    }

    try {
        return [DateTime]::ParseExact($DateString, "dd-MM-yyyy", $null)
    }
    catch {
        Write-Error "Invalid date format: $DateString. Expected format: DD-MM-YYYY"
        exit 1
    }
}

$cutoffDate = Get-DanishDateFormat -DateString $date


Function Get-DiffSinceDateDWH  {
    param (
        [Parameter(Mandatory=$true)][string]$Repo,
        [Parameter(Mandatory=$true)][string]$SinceDate
    )

    $BaseCommit = git -C $Repo rev-list -n 1 --before=$SinceDate HEAD

    function Get-ParsedGitDiff {
        param (
            [Parameter(ValueFromPipeline = $true)]
            [string]$Line
        )

        process {
            if ([string]::IsNullOrWhiteSpace($Line)) { return }

            if ($Line -match '^(?<Status>[ADM])\s+(?<Path>.+)$') {
                $status   = $Matches.Status
                $fullPath = $Matches.Path

                if ($fullPath -match '^DWH[\\/][^\\/]+[\\/][^\\/]+[\\/][^\\/]+\.sql$') {
                    $parts = $fullPath -split '[\\/]'
                    $schema   = $parts[1]
                    $type     = $parts[2]
                    $fileName = $parts[3]

                    $obj = [PSCustomObject]@{
                        ChangeType = $status
                        FullPath   = $fullPath
                        Schema     = $schema
                        Type       = $type
                        FileName   = $fileName
                        DiffText   = $null
                        AddedLines   = @()
                        RemovedLines = @()
                    }

                    if ($status -eq 'M') {
                        $diffText = git -C $Repo diff -U3 $BaseCommit -- $fullPath
                        $obj.DiffText = $diffText

                        $addedLinesWithNumbers = @()
                        $removedLinesWithNumbers = @()
                        
                        $currentOldLine = 0
                        $currentNewLine = 0
                        
                        foreach ($line in $diffText -split "`n") {
                            if ($line -match '^@@\s+-(\d+)(?:,\d+)?\s+\+(\d+)(?:,\d+)?\s+@@') {
                                $currentOldLine = [int]$matches[1]
                                $currentNewLine = [int]$matches[2]
                                continue
                            }

                            if ($line -like '---*' -or $line -like '+++*' -or $line -like 'diff --git*' -or $line -like 'index *') {
                                continue
                            }
                            if ($line -match '^-(.*)$' -and $line -notlike '---*') {
                                $content = $matches[1]
                                $removedLinesWithNumbers += [PSCustomObject]@{
                                    LineNumber = $currentOldLine
                                    Content = $content
                                }
                                $currentOldLine++
                            }
                            elseif ($line -match '^\+(.*)$' -and $line -notlike '+++*') {
                                $content = $matches[1]
                                $addedLinesWithNumbers += [PSCustomObject]@{
                                    LineNumber = $currentNewLine
                                    Content = $content
                                }
                                $currentNewLine++
                            }
                            elseif ($line -match '^ (.*)$' -or ($line -ne '' -and -not ($line -match '^[\+\-@]'))) {
                                $currentOldLine++
                                $currentNewLine++
                            }
                        }
                        
                        $obj.AddedLines = $addedLinesWithNumbers
                        $obj.RemovedLines = $removedLinesWithNumbers
                    }

                    $obj
                }
            }
            elseif ($Line -match '^R\d+\s+(?<OldPath>\S+)\s+(?<NewPath>\S+)$') {
                $status   = "R"
                $oldPath  = $Matches.OldPath
                $fullPath = $Matches.NewPath

                if ($fullPath -match '^DWH[\\/][^\\/]+[\\/][^\\/]+[\\/][^\\/]+\.sql$') {
                    $parts = $fullPath -split '[\\/]'
                    $schema   = $parts[1]
                    $type     = $parts[2]
                    $fileName = $parts[3]

                    [PSCustomObject]@{
                        ChangeType = $status
                        FullPath   = $fullPath
                        OldPath    = $oldPath
                        Schema     = $schema
                        Type       = $type
                        FileName   = $fileName
                        DiffText   = $null
                        AddedLines   = @()
                        RemovedLines = @()
                    }
                }
            }
        }
    }

    $gitdiffs = git -C $Repo diff --name-status --diff-filter=ADMR $BaseCommit -- DWH/ | Get-ParsedGitDiff
    return $gitdiffs
}


Function Get-ParsedRefactorLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RefactorLogPath
        ,[Parameter(Mandatory=$false)]
        [string]$AfterDate
        ,[Parameter(Mandatory=$false)]
        [string]$BeforeDate
        ,[Parameter(Mandatory=$false)]
        [switch]$ExportMarkdown  = $false
    )

    function Get-FullObjectName {
        param(
            [string]$ElementName,
            [string]$ParentElementName
        )
    
        $elementClean = $ElementName -replace '\[|\]', ''
    
        if ($elementClean -match '\.') {
            return $elementClean
        }
        if ($ParentElementName) {
            $parentClean = $ParentElementName -replace '\[|\]', ''
            return "$parentClean.$elementClean"
        }
    
        return $elementClean
    }

    $afterDateTime = $AfterDate
    $beforeDateTime =  $BeforeDate

    [xml]$refactorLog = Get-Content -Path $RefactorLogPath

    $operations = @()

    foreach ($operation in $refactorLog.Operations.Operation) {
        $changeDateTime = [DateTime]::ParseExact($operation.ChangeDateTime,"MM/dd/yyyy HH:mm:ss", $null)
    
        if ($afterDateTime -and $changeDateTime -lt $afterDateTime) {
            continue
        }
        if ($beforeDateTime -and $changeDateTime -gt $beforeDateTime) {
            continue
        }
    
        $operationType = $operation.Name
        $oldName = $null
        $newName = $null
    
        if ($operationType -eq "Rename Refactor") {
            $elementName = ($operation.Property | Where-Object { $_.Name -eq "ElementName" }).Value
            $newNameValue = ($operation.Property | Where-Object { $_.Name -eq "NewName" }).Value
            $parentElementName = ($operation.Property | Where-Object { $_.Name -eq "ParentElementName" }).Value
        
            $oldFullName = Get-FullObjectName -ElementName $elementName -ParentElementName $parentElementName
        
            if ($oldFullName -match '^(.+)\.([^.]+)$') {
                $schema = $matches[1]
                $newNameClean = $newNameValue -replace '\[|\]', ''
                $newName = "$schema.$newNameClean"
            } else {
                $newName = Get-FullObjectName -ElementName $newNameValue -ParentElementName $parentElementName
            }
        
            $oldName = $oldFullName
        }
        elseif ($operationType -eq "Move Schema") {
            $elementName = ($operation.Property | Where-Object { $_.Name -eq "ElementName" }).Value
            $newSchemaValue = ($operation.Property | Where-Object { $_.Name -eq "NewSchema" }).Value
            $elementClean = $elementName -replace '\[|\]', ''
        
            if ($elementClean -match '^(.+)\.([^.]+)$') {
                $oldSchema = $matches[1]
                $objectName = $matches[2]
            
                $oldName = "$oldSchema.$objectName"
                $newName = "$newSchemaValue.$objectName"
            }
        }
    
        if ($oldName -and $newName) {
            $operations += [PSCustomObject]@{
                OldName = $oldName
                NewName = $newName
                OperationType = $operationType
                ChangeDateTime = $changeDateTime
            }
        }
    }

    $objectChains = @{}

    foreach ($op in $operations | Sort-Object ChangeDateTime) {
        $found = $false
        foreach ($key in @($objectChains.Keys)) {
            if ($objectChains[$key].CurrentName -eq $op.OldName) {
                $objectChains[$key].NameHistory.Add("$($op.NewName) ($($op.ChangeDateTime.ToString('dd-MM-yyyy'))) ")
                $objectChains[$key].CurrentName = $op.NewName
                $objectChains[$key].LastChangeDateTime = $op.ChangeDateTime
            
                if ($op.OperationType -eq "Rename Refactor") {
                    $objectChains[$key].RenameCount++
                }
                elseif ($op.OperationType -eq "Move Schema") {
                    $objectChains[$key].SchemaMoveCount++
                }
            
                $found = $true
                break
            }
        }
        if (-not $found) {
            $objectChains[$op.OldName] = [PSCustomObject]@{
                FirstName = $op.OldName
                CurrentName = $op.NewName
                NameHistory = [System.Collections.Generic.List[string]]@(
                    $op.OldName,
                    "$($op.NewName) ($($op.ChangeDateTime.ToString('dd-MM-yyyy'))) "
                )
                FirstChangeDateTime = $op.ChangeDateTime
                LastChangeDateTime = $op.ChangeDateTime
                RenameCount = if ($op.OperationType -eq "Rename Refactor") { 1 } else { 0 }
                SchemaMoveCount = if ($op.OperationType -eq "Move Schema") { 1 } else { 0 }
            }
        }
    }

    $results = $objectChains.Values | Sort-Object FirstChangeDateTime

    Write-Host "=======================`n" -ForegroundColor Cyan

    if ($afterDateTime) {
        Write-Host "Filtreret: Efter $($AfterDate)" -ForegroundColor Yellow
    }
    if ($beforeDateTime) {
        Write-Host "Filtreret: før $($BeforeDate)" -ForegroundColor Yellow
    }
    return $results
}

$gitChanges = Get-DiffSinceDateDWH -Repo $RepoPath -sinceDate $cutoffDate
$refactorChanges = Get-ParsedRefactorLog -RefactorLogPath $RefactorLogPath -AfterDate $cutoffDate

Add-Type -AssemblyName System.Web

$detailedDiffs = @()

$gitChanges | ForEach-Object {
    if ($_.AddedLines -or $_.RemovedLines) {
        $added = $_.AddedLines
        $removed = $_.RemovedLines
        $totalLines = $added.Count + $removed.Count
        
        $detailedDiffHtml = @"
<div style='margin: 20px 0; padding: 10px; border: 2px solid #ccc; background-color: #f9f9f9;'>
    <h3 style='color: #333; margin-top: 0;'>$($_.FullPath)</h3>
    <p><strong>Ændringstype:</strong> $($_.ChangeType) | <strong>Type:</strong> $($_.Type) | <strong>Schema:</strong> $($_.Schema)</p>
"@
        
        $detailedDiffHtml += @"
    <table cellpadding='4' cellspacing='0' border='1' style='width:100%; border-collapse: collapse; font-size: 11px; font-family: Courier New, monospace;'>
        <tr>
            <th bgcolor='#ffcccc' style='padding: 4px; width: 60px;'>Linje</th>
            <th bgcolor='#ffcccc' style='padding: 4px;'>Fjernet ($($removed.Count) linjer)</th>
            <th bgcolor='#ccffcc' style='padding: 4px; width: 60px;'>Linje</th>
            <th bgcolor='#ccffcc' style='padding: 4px;'>Tilføjet ($($added.Count) linjer)</th>
        </tr>
"@
        
        $maxRows = [Math]::Max($added.Count, $removed.Count)
        for ($i = 0; $i -lt $maxRows; $i++) {
            $removedLineNum = '&nbsp;'
            $removedLine = '&nbsp;'
            if ($i -lt $removed.Count) {
                $removedLineNum = $removed[$i].LineNumber
                $removedLine = [System.Web.HttpUtility]::HtmlEncode($removed[$i].Content)
            }

            $addedLineNum = '&nbsp;'
            $addedLine = '&nbsp;'
            if ($i -lt $added.Count) {
                $addedLineNum = $added[$i].LineNumber
                $addedLine = [System.Web.HttpUtility]::HtmlEncode($added[$i].Content)
            }
            
            $detailedDiffHtml += @"
        <tr>
            <td bgcolor='#ffe6e6' style='padding: 4px; text-align: right; color: #666; font-weight: bold;'>$removedLineNum</td>
            <td bgcolor='#ffe6e6' style='padding: 4px; vertical-align: top;'>$removedLine</td>
            <td bgcolor='#e6ffe6' style='padding: 4px; text-align: right; color: #666; font-weight: bold;'>$addedLineNum</td>
            <td bgcolor='#e6ffe6' style='padding: 4px; vertical-align: top;'>$addedLine</td>
        </tr>
"@
        }
        
        $detailedDiffHtml += "</table></div>"
        $detailedDiffs += $detailedDiffHtml
        $_.AddedLines = "$totalLines linjer ændret ($($removed.Count) fjernet, $($added.Count) tilføjet)"
        $_.RemovedLines = ''
    } else {
        $_.AddedLines = 'Ingen ændringer'
        $_.RemovedLines = ''
    }
}

# Prepare Refactor Log changes for display
$refactorChangesDisplay = $refactorChanges | Select-Object `
    @{Label='Første Navn';Expression={$_.FirstName}},
    @{Label='Nuværende Navn';Expression={$_.CurrentName}},
    @{Label='Navnehistorik';Expression={$_.NameHistory -join ' -> '}},
    @{Label='Omdøbninger';Expression={$_.RenameCount}},
    @{Label='Skemaskift';Expression={$_.SchemaMoveCount}}
# Prepare Git changes for display
$gitChangesDisplay = $gitChanges | Select-Object `
    ChangeType, Type, @{Label='FileName';Expression={"$($_.Schema).$($_.FileName)"}}, @{Label='Linjeændringer';Expression={$_.AddedLines}} |
    Sort-Object Type, FileName

$addedFiles   = $gitChangesDisplay | Where-Object { $_.ChangeType -eq 'A' -and $_.Type -in @('Tables', 'Views') }
$droppedFiles = $gitChangesDisplay | Where-Object { $_.ChangeType -eq 'D' -and $_.Type -in @('Tables', 'Views') }
$modifiedFiles = $gitChangesDisplay | Where-Object { $_.ChangeType -eq 'M' }

function Convert-ToHtmlTable {
    param (
        [Parameter(Mandatory=$true)][AllowNull()]$data,
        [Parameter(Mandatory=$true)]$title,
        [Parameter(Mandatory=$false)]$excludeProperties = @()
    )

    if (-not $data) { return "<h3>$title</h3><p>Ingen ændringer</p>" }

    # Build list of properties to exclude
    $allExclusions = @('ChangeType') + $excludeProperties
    
    # Remove specified properties before converting to HTML
    $dataFiltered = $data | Select-Object * -ExcludeProperty $allExclusions

    $html = "<h3>$title</h3>"
    $html += $dataFiltered | ConvertTo-Html -Fragment
    
    return $html
}

# Create HTML sections
$refactorHtml = Convert-ToHtmlTable $refactorChangesDisplay "🔄 Refactorlog Ændringer (Omdøbninger og skemaskift)"
$addedHtml    = Convert-ToHtmlTable $addedFiles "➕ Tilføjede Filer" -excludeProperties @('Linjeændringer')
$droppedHtml  = Convert-ToHtmlTable $droppedFiles "➖ Slettede Filer" -excludeProperties @('Linjeændringer')
$modifiedHtml = Convert-ToHtmlTable $modifiedFiles "✏️ Modificerede Filer"

$totalAdded = $addedFiles.Count
$totalDropped = $droppedFiles.Count
$totalModified = $modifiedFiles.Count
$totalRefactorChanges = $refactorChanges.Count

$summaryHtml = @"
<div style='background-color: #e7f3ff; border: 1px solid #2196F3; padding: 15px; margin: 20px 0; border-radius: 5px;'>
    <h3 style='color: #1976D2; margin-top: 0;'>📊 Oversigt</h3>
    <ul style='margin: 10px 0;'>
        <li><strong>Refactorlog ændringer:</strong> $totalRefactorChanges objekter</li>
        <li><strong>Tilføjet:</strong> $totalAdded filer</li>
        <li><strong>Slettet:</strong> $totalDropped filer</li>
        <li><strong>Modificeret:</strong> $totalModified filer</li>
        <li><strong>Samlede ændringer:</strong> $($gitChanges.Count) filer</li>
    </ul>
    <p style='margin: 10px 0 0 0;'><em>📎 Se vedhæftet HTML-rapport for detaljerede linje-for-linje ændringer.</em></p>
</div>
"@

$bodyHtml = @"
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
table { border-collapse: collapse; width: 100%; margin-bottom: 20px; font-family: Arial, sans-serif; }
th, td { border: 1px solid black; padding: 6px; text-align: left; font-size: 12px; vertical-align: top; }
th { background-color: #f2f2f2; font-weight: bold; }
h3 { color: #1976D2; border-bottom: 2px solid #2196F3; padding-bottom: 5px; margin-top: 30px; }
</style>
</head>
<body style='font-family: Arial, sans-serif;'>
<h2>Ugentlig DWH Ændringsrapport</h2>
<p><strong>Rapportdato:</strong> $(Get-Date -Format "dd-MM-yyyy HH:mm")</p>
<p><strong>Ændringer siden:</strong> $cutoffDate</p>
$summaryHtml
$refactorHtml
$addedHtml
$droppedHtml
$modifiedHtml
</body>
</html>
"@

$attachments = @()

if ($detailedDiffs.Count -gt 0) {
    $detailedReportHtml = @"
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
h1 { color: #333; border-bottom: 3px solid #2196F3; padding-bottom: 10px; }
h3 { color: #555; margin-top: 0; }
table { border-collapse: collapse; width: 100%; margin: 10px 0; background-color: white; }
th, td { border: 1px solid #ccc; padding: 6px; text-align: left; font-size: 11px; vertical-align: top; }
th { font-weight: bold; }
.summary-box { background-color: #e7f3ff; border: 1px solid #2196F3; padding: 15px; margin: 20px 0; border-radius: 5px; }
.line-number { text-align: right; color: #666; font-weight: bold; width: 60px; }
</style>
</head>
<body>
<h1>📋 Detaljeret DWH Ændringsrapport</h1>
<div class="summary-box">
    <p><strong>Rapportdato:</strong> $(Get-Date -Format "dd-MM-yyyy HH:mm")</p>
    <p><strong>Ændringer siden:</strong> $($cutoffDate.ToString('dd-MM-yyyy'))</p>
    <p><strong>Totalt antal ændrede filer:</strong> $($detailedDiffs.Count)</p>
    <p><em>Linjenumre viser positionen i filen hvor ændringen skete. Det svarer ikke til positionen ved CREATE AS templaten, da der tilføjes nogle linjer i toppen.</em></p>
</div>
<hr/>
$($detailedDiffs -join "`n")
</body>
</html>
"@
    
    $detailedReportPath = "$env:TEMP\DWH_Detaljeret_Rapport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $detailedReportHtml | Out-File -FilePath $detailedReportPath -Encoding UTF8
    $attachments += $detailedReportPath
}

$mailParams = @{
    From = $mailsender
    To = $mailsender
    Subject = "Ugentlig DWH Ændringsrapport - $(Get-Date -Format 'dd-MM-yyyy')"
    Body = $bodyHtml
    BodyAsHtml = $true
    SmtpServer = $SMTPServer
    Encoding = [System.Text.Encoding]::UTF8
}

if ($attachments.Count -gt 0) {
    $mailParams.Attachments = $attachments
}

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer)
$msg = New-Object System.Net.Mail.MailMessage
$msg.From = "radfpqlikview@ankl.dk"
$msg.To.Add($MailTo)
$msg.Subject = "Ugentlig DWH Ændringsrapport - $(Get-Date -Format 'dd-MM-yyyy')"
$msg.Body = $bodyHtml
$msg.IsBodyHtml = $true
$msg.BodyEncoding = [System.Text.Encoding]::UTF8
$msg.SubjectEncoding = [System.Text.Encoding]::UTF8

if ($attachments.Count -gt 0) {
    foreach ($att in $attachments) {
        $attachment = New-Object System.Net.Mail.Attachment($att)
        $msg.Attachments.Add($attachment)
    }
}

$smtp.Send($msg)
$msg.Dispose()

Write-Host "Email sendt!" -ForegroundColor Green