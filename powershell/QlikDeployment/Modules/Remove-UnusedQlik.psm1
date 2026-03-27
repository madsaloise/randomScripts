[cmdletbinding()]
param(
    [string] $TargetFolder
)
#checks qvw files no longer in repo and deletes them


$SubFolderNames = @('RP', 'OK', 'PA', 'PL') #Folders to check 

$SubFolders = Get-ChildItem -Directory -Path $TargetFolder |
    Where-Object { $_.Name -in $SubFolderNames }
Write-Output "Checking $($SubFolders.Count) subfolders: $($SubFolders.Name -join ', ')"

$qvwFiles = $SubFolders | ForEach-Object {
    Get-ChildItem -File -Recurse -Filter '*.qvw' -Path $_.FullName
}
$filesNotInSource = $qvwFiles | Where-Object {
    $prjFolder = Join-Path $_.DirectoryName "$($_.BaseName)-prj"
    -not (Test-Path $prjFolder -PathType Container)
}
Write-Output "Found $($filesNotInSource.Count) orphaned files to delete"

foreach ($file in $filesNotInSource) {
    $qvwFile = $file.FullName
    $logFile = Join-Path $file.DirectoryName "$($file.Name).log"

    Write-Output "Deleting orphaned: $qvwFile"
    Remove-Item $qvwFile -Force

    if (Test-Path $logFile) {
        Write-Output "Deleting matching .log: $logFile"
        Remove-Item $logFile -Force
    }
}

Write-Output "Done. Cleanup complete."