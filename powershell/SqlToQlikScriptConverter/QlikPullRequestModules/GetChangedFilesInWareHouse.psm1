Function Get-ChangedFilesInWareHouse {
    <#
    .SYNOPSIS
    Retrieves and categorizes changed SQL objects (tables, views, and procedures) from a DeployReport XML file.

    .DESCRIPTION
    The Get-ChangedFilesInWareHouse function parses a deploy report XML file to identify changes made to database objects. 
    It extracts operations such as Drop, Rename, MoveSchema, Create, Alter, and TableRebuild, returning a list of objects affected during deployment.

    .PARAMETER Path
    Specifies the full path to the deploy report XML file to analyze. This parameter is mandatory.

    .PARAMETER nameMatch
    (Optional) A regular expression pattern used to filter results by object name.

    .PARAMETER xmlSchema
    (Optional) The XML schema namespace to use for parsing deploy report nodes.
    Defaults to: http://schemas.microsoft.com/sqlserver/dac/DeployReport/2012/02

    .PARAMETER dwhOnly
    If specified, limits the parsing to the Data Warehouse (DWH) section of the deploy report.

    .PARAMETER Unique
    If specified, returns only unique object names by grouping duplicates.

    .EXAMPLE
    PS> Get-ChangedFilesInWareHouse -Path "C:\Reports\DeployReport.xml" -nameMatch "PS|KR" -Unique

    Returns only unique objects whose names contain 'PS' or 'KR'.

    .OUTPUTS
    [PSCustomObject]
    Each returned object includes the following properties:
    - Schema  : Database schema name
    - Name    : Object name
    - FileType: Type of object (SqlProcedure, SqlView, SqlTable)
    - Reason  : Type of change (Drop, Rename Refactor, Move Schema, AddOrChange)
    #>

    param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $false)][string]$nameMatch,
    [Parameter(Mandatory = $false)][string]$xmlSchema = "http://schemas.microsoft.com/sqlserver/dac/DeployReport/2012/02",
    [switch]$dwhOnly,
    [switch]$Unique
    )

    [xml]$xml = Get-Content $Path

    $nameSpaceMngr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $nameSpaceMngr.AddNamespace("dr", $xmlSchema)

    if ($dwhOnly) {
        $relevantNode = $xml.SelectSingleNode("/DeployReports/DWH")
    } else {
        $relevantNode = $xml
    }

    #<I PRIORITERET RÆKKEFØLGE>
    $items = ($relevantNode.SelectNodes(".//dr:Operation[@Name='Drop']/dr:Item[@Type='SqlProcedure' or @Type='SqlView' or @Type='SqlTable']", $nameSpaceMngr) ) | ForEach-Object {
        $parts = $_.Value -replace '\[|\]' -split '\.'
        [PSCustomObject]@{
            Schema    = $parts[0]
            Name      = $parts[1]
            FileType  = $_.Type
            Reason    = "Drop"
        }
    }

    $items += ($relevantNode.SelectNodes(".//dr:Operation[@Name='Rename']/dr:Item[@Type='SqlProcedure' or @Type='SqlView' or @Type='SqlTable']", $nameSpaceMngr) ) | ForEach-Object {
        $parts = $_.Value -replace '\[|\]' -split '\.'
        [PSCustomObject]@{
            Schema    = $parts[0]
            Name      = $parts[1]
            FileType  = $_.Type
            Reason    = "Rename Refactor"
        }
    }

    $items += ($relevantNode.SelectNodes(".//dr:Operation[@Name='MoveSchema']/dr:Item[@Type='SqlProcedure' or @Type='SqlView' or @Type='SqlTable']", $nameSpaceMngr) ) | ForEach-Object {
        $parts = $_.Value -replace '\[|\]' -split '\.'
        [PSCustomObject]@{
            Schema    = $parts[0]
            Name      = $parts[1]
            FileType  = $_.Type
            Reason    = "Move Schema"
        }
    }

    $items += ($relevantNode.SelectNodes(".//dr:Operation[@Name = 'Create' or @Name = 'Alter']/dr:Item[@Type='SqlProcedure' or @Type='SqlView' or @Type='SqlTable']", $nameSpaceMngr) ) | ForEach-Object {
        $parts = $_.Value -replace '\[|\]' -split '\.'
        [PSCustomObject]@{
            Schema    = $parts[0]
            Name      = $parts[1]
            FileType  = $_.Type
            Reason    = "AddOrChange"
        }
    }

    $items += ($relevantNode.SelectNodes(".//dr:Operation[@Name = 'TableRebuild']/dr:Item[@Type='SqlTable']", $nameSpaceMngr) ) | ForEach-Object {
        $parts = $_.Value -replace '\[|\]' -split '\.'
        [PSCustomObject]@{
            Schema    = $parts[0]
            Name      = $parts[1]
            FileType  = "SqlTable"
            Reason    = "AddOrChange"
        }
    }

    if ($PSBoundParameters.ContainsKey('nameMatch') ) { 
        $items = $items | Where-Object {$_.Name -match $nameMatch}
    }

    if ($Unique) {
        $curatedItems = $items | Group-Object -Property Name | ForEach-Object { $_.Group[0]}
        return $curatedItems
    } else {
        return $items
    } 
}
Export-ModuleMember Get-ChangedFilesInWareHouse

