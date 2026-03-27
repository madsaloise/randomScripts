
$Path = "C:\Path\To\Repo"

$StoredProcedureName = "Load_KR_Sigtelser"

function Set-StoredProcedureClipboard {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string] $ScriptName
    )

    $tableName = $ScriptName -replace 'Load_', ''
    $procFile = Get-ChildItem -Path $Path -Filter "$($ScriptName).sql" -Recurse | Select-Object -First 1
    if (-not $procFile) {
        Write-Host  "Stored Procedure '$($ScriptName).sql' ej fundet"
        Write-Host "Sørg for at både fil og sti er skrevet korrekt."
        Exit 0
    }

    $procSql = Get-Content $procFile.FullName -Raw
    $tableDefinitions, $tableQVDefinitions = Get-SQLTableDefinitions -Path $Path -tableName $tableName

    if (-not $tableDefinitions) {
        Write-Host "Ingen tabeldefinitioner fundet. Hedder tabellen det samme som Stored Procedure minus Load_ ?"
        Write-Host "Sørg for, at SP og Table har samme navneformat"
        Exit 0
    }
    $procSql = Remove-SQLSyntaxStoredProcedure -procedureDefinitions $procSql

    $tempTableDefinitions = Invoke-CreateTempTable -procSql $procSql -tableDefinitions $tableDefinitions                  
   
    $procSql = $procSql -replace [regex]::Escape('$(Exploration)'), 'Exploration'

    # Genererer output
    $query = @()
    $query += $tempTableDefinitions
    $query += $procSql    
    
    #Oversætter til temptables i QV
    foreach ($table in $tableDefinitions.Keys) {
        $query = $query -replace [regex]::Escape($table), $tableQVDefinitions[$table]
    }
    Set-Clipboard -Value $query
    Write-Host ""
    Write-Host "Query copied to clipboard!"
}

function Remove-SQLSyntaxStoredProcedure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject] $procedureDefinitions
    )
    #Tager kun fra Begin transaction til Commit Transaction
    $procedureDefinitions = $procedureDefinitions -creplace '(?i)truncate table .*\r?\n?', ''
    $procedureDefinitions = $procedureDefinitions -replace "[\[\]]", ""

    $pattern = "(?is)BEGIN TRANSACTION(.*?)COMMIT TRANSACTION"
    $patternMatch = [regex]::Matches($procedureDefinitions, $pattern)
   
    $extractedContent = $patternMatch.Groups[1].Value
    return $extractedContent
}



Function Get-SQLTableDefinitions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter (Mandatory = $false)]
        [string]$tableName
    )
    $tableDefinitions = @{}
    $tableQVDefinitions = @{}

    Get-ChildItem -Path $Path -Filter "$($tableName).sql" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        # --- CREATE TABLE ---
        $tablePattern = 'CREATE\s+TABLE\s+(?:\[(?<schema>[A-Za-z0-9_]+)\]|\b(?<schema>[A-Za-z0-9_]+)\b)?\s*\.\s*(?:\[(?<table>[A-Za-z0-9_]+)\]|\b(?<table>[A-Za-z0-9_]+)\b)\s*\((?<cols>[\s\S]*?)\)\s*;'

        if ($content -match $tablePattern) {
            $schema = if ($matches['schema']) { $matches['schema'] } else { 'dbo' }
            $table  = $matches['table']
            $columnsFull = $matches['cols'].Trim()
            $columns = ($columnsFull -split "`r?`n" | Where-Object {
                $line = $_.Trim()
                -not ($line -match '^(PRIMARY\s+KEY|FOREIGN\s+KEY|CONSTRAINT|UNIQUE|CHECK)\b')
            }) -join "`n"
            $key = "$schema.$table".ToLowerInvariant()
            $tableDefinitions[$key] = $columns
            $tableQVDefinitions[$key] = "#$key" -replace "\.", "_"
        }
    }

    if ($tableDefinitions.Count -eq 0) {
        
        throw "Get-SQLTableDefinitions: No CREATE TABLE or VIEW definitions found in $Path. Muligvis mangler der et semikolon til sidst i CREATE TABLE statement"
    }
    return $tableDefinitions, $tableQVDefinitions
}


Function Invoke-CreateTempTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $procSql,
        [Parameter(Mandatory = $true)]
        [hashtable] $tableDefinitions
    )
    $tableInsertMatches = [regex]::Matches(
        $procSql,
        'INSERT\s+INTO\s+(?:\[(?<schema>[A-Za-z0-9_]+)\]|\b(?<schema>[A-Za-z0-9_]+)\b)?\s*\.?\s*(?:\[(?<table>[A-Za-z0-9_]+)\]|\b(?<table>[A-Za-z0-9_]+)\b)', #Robot-RegEX
        'IgnoreCase'
    )

    $uniqueTables = @{}

    foreach ($match in $tableInsertMatches) {
        $schema = $match.Groups['schema'].Value
        $tableName = $match.Groups['table'].Value

        if (-not $schema) {
            $schema = $ProcedureSchema
        }

        $key = "$schema.$tableName".ToLowerInvariant()

        if ($tableDefinitions.ContainsKey($key) -and -not $uniqueTables.ContainsKey($tableName)) {
            $uniqueTables["$schema.$tableName"] = $key
        }
    }

    # Byg CREATE TABLE for alle unikke forekomster af tabellen
    $tempTableDefinitions = @()
    foreach ($tableName in $uniqueTables.Keys) {
        $key = $uniqueTables[$tableName]
        $cols = $tableDefinitions[$key]
        $tempTableDefinitions += "CREATE TABLE $tableName (`n$cols`n);`n"
    }
    return $tempTableDefinitions
}


Set-StoredProcedureClipboard -Path $Path -ScriptName $StoredProcedureName