function Get-VarFromQVLog {
    param (
    [string]$Path,
    [string]$fileName
    )
 
    $logFile = Get-ChildItem -Path $Path -Filter "$($fileName)"
    $logFileVarList = [pscustomobject]@{
        "$($logFile.Name)" = @()
    }
    #Sti til input QVW filer
    $fileContent = Get-Content $logFile.FullName
    foreach ($line in $fileContent) {
        $lineToFill = $line
        $line = $line.ToUpper()
        #Linjer med SET eller LET
        if ($line -match "LET|SET" -and $line -match "=" ) {
            $letIndex = $line.IndexOf("LET")
            $setIndex = $line.IndexOf("SET")
            if ($letIndex -ge 0 -or $setIndex -ge 0) {
                # Skipper datostempel før funktionskald
                $substring = if ($letIndex -ge 0) { $lineToFill.Substring($letIndex) } else { $lineToFill.Substring($setIndex) }
                $splitArray = $substring.Split('=')
                $substring = $splitArray[0]
                $substring = $substring.Split(" ")[1]
                $substring = $substring -replace "\s", ""

                $substringValue = $splitArray | Where-Object {$_ -ne $splitArray[0]}
                $substringValue = $substringValue.TrimEnd()
                $substringValue = $substringValue.TrimStart()
            }
            $logFileVarList.$($logFile.Name) += @{ 
                "Variable" = $substring
                "Value" = $substringValue
            }
        }
    }
    return $logFileVarList
}
      
function Get-VarFromQVW {
    param(
    [string]$Path,
    [string]$fileName
    )
    
    $file = Get-ChildItem -Path $Path -Filter $fileName

    $document = $qlikView.OpenDoc($file.FullName)  
    if ($document) {
        $variables = $document.GetVariableDescriptions()
        $document.CloseDoc()
        $document.GetApplication.Quit
    }    
    $data = [pscustomobject]@{
    "$($file.Name)" = @()
    }
    for ($indx = 0; $indx  -lt $variables.Count;$indx++) {
        $data.$($file.Name) += @{
            Variable       = $variables.Item($indx).Name
            Value = $variables.Item($indx).RawValue
            IsReserved = $variables.Item($indx).IsReserved
        }
    }
    return $data
}

function Add-VarToLoadScript {
    param(
    [string]$Path,
    [string]$fileBaseName
    )
    $fileName = "$($fileBaseName).qvw"
    $logFileName = "$($fileName).log"

    $logfileVarList = Get-VarFromQVLog -Path $Path -fileName $logFileName
    $logfileVarList = $logfileVarList.$logFileName

    $QVVarList = Get-VarFromQVW -Path $Path -fileName $fileName
    $QVVarList = $QVVarList.$fileName

    $xmlLoadScriptFile = Get-ChildItem -Path "$($Path)\$($fileBaseName)-prj" -Filter "LoadScript.txt"
    Add-Content -Path $xmlLoadScriptFile.FullName -Value "///`$tab VariableAdded" -Encoding UTF8
    foreach ($item in $QVVarList) {
        if ((-not $logfileVarList.Variable.Contains($item.Variable)) -and $item.IsReserved -eq $false) {
            Write-Host "SET $($item.Variable) = $($item.Value);"
            if ($item.Variable -eq "1" -or $item.Variable -eq "0" -or $item.Variable -eq "0") { 
                Add-Content -Path $xmlLoadScriptFile.FullName -Value "SET `"$($item.Variable)`" = $($item.Value);" -Encoding UTF8
            } else {Add-Content -Path $xmlLoadScriptFile.FullName -Value "SET $($item.Variable) = $($item.Value);" -Encoding UTF8
            }
        }
    }
     

}

$qlikViewDirectory = "\\fileshare\PROD"

$qlikViewFiles = Get-ChildItem -Recurse -Path $qlikViewDirectory -Filter "*.qvw"
$qlikView = New-Object -ComObject "QlikTech.QlikView"

foreach ($file in $qlikViewFiles) {

$Path = $file.DirectoryName
$fileName = $file.BaseName

 Add-VarToLoadScript -Path $Path -fileBaseName $fileName
}
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($qlikView) | Out-Null
Remove-Variable qlikView


