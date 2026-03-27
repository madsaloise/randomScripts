param(
    [Parameter(Mandatory=$false)]
    [string]$RefactorLogPath
    
    ,[Parameter(Mandatory=$false)]
    [string]$AfterDate = "15-01-2026" ##dd-MM-yyyy
    
    ,[Parameter(Mandatory=$false)]
    [string]$BeforeDate  ##dd-MM-yyyy

    ,[Parameter(Mandatory=$false)]
    [switch]$ExportMarkdown
)

function Parse-Date {
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

$afterDateTime = Parse-Date $AfterDate
$beforeDateTime = Parse-Date $BeforeDate

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

#Lineage
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

# Output 
$results = $objectChains.Values | Sort-Object FirstChangeDateTime

if ($afterDateTime) {
    Write-Host "Filtreret: Efter $($afterDateTime.ToString('dd-MM-yyyy'))" -ForegroundColor Yellow
}
if ($beforeDateTime) {
    Write-Host "Filtreret: før $($beforeDateTime.ToString('dd-MM-yyyy'))" -ForegroundColor Yellow
}

$results | Format-Table -AutoSize @{
    Label = "First Name"
    Expression = { $_.FirstName }
    Width = 50
}, @{
    Label = "Last Name"
    Expression = { $_.CurrentName }
    Width = 50
}, @{
    Label = "Renames"
    Expression = { $_.RenameCount }
    Width = 8
}, @{
    Label = "Schema Moves"
    Expression = { $_.SchemaMoveCount }
    Width = 13
}, @{
    Label = "NameHistory"
    Expression = { $_.NameHistory }
    Width = 45
}


#Til markdown
$markdownLines = @()

$markdownLines += '| First Name | Last Name | Renames | Schema Moves | Name History |'
$markdownLines += '|------------|-----------|---------|--------------|--------------|'

foreach ($r in $results) {
    $markdownLines += '| {0} | {1} | {2} | {3} | {4} |' -f `
        $r.FirstName,
        $r.CurrentName,
        $r.RenameCount,
        $r.SchemaMoveCount,
        ($r.NameHistory -join ' → ')
}

if ($ExportMarkdown) {

    Add-Type -AssemblyName System.Windows.Forms

    $dialog = New-Object System.Windows.Forms.SaveFileDialog
    $dialog.Filter = 'Markdown files (*.md)|*.md|All files (*.*)|*.*'
    $dialog.Title  = 'Save Refactor Log as Markdown'
    $dialog.FileName = 'RefactorLog_SSDTAnalysis.md'

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $markdownLines | Out-File -FilePath $dialog.FileName -Encoding utf8
        Write-Host "Markdown exported to $($dialog.FileName)" -ForegroundColor Green
    }
    else {
        Write-Host "Markdown export canceled." -ForegroundColor Yellow
    }
}
