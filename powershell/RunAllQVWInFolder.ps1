$qlikViewDirectory = "\\fileshare\PROD\"

$qlikViewFiles = Get-ChildItem -Path $qlikViewDirectory -Filter "*.qvw" -Recurse
$qlikView = New-Object -ComObject "QlikTech.QlikView"

foreach ($file in $qlikViewFiles) {
        $file.BaseName
        $file.DirectoryName
        $file.FullName
        Write-Host "--------"
        $documentPath = $file.FullName
        $document = $qlikView.OpenDoc($documentPath)       
        if ($document) {
                $document.Reload($true)
                $document.SaveAs("$($file.BaseName).qvw")
                $document.CloseDoc()
                $document.GetApplication.Quit

        }
}
Write-Host "Alle filer i mappen er reloaded."
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($qlikView) | Out-Null
Remove-Variable qlikView