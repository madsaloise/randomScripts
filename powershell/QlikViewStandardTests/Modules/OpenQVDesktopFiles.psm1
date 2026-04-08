Function Start-QVWDesktop {
    param(
        [string]$documentPath,
        [switch]$Reload
    )

    try {
        $qlikView = New-Object -ComObject "QlikTech.QlikView"
        $qvProcess = Get-Process -Name "Qv" -ErrorAction SilentlyContinue
        if (-not $qvProcess) {
            Write-EnhancedLog "Starting QlikView Desktop..." -ForegroundColor Cyan
            Start-Process "Qv.exe" -WindowStyle Normal
            Start-Sleep -Seconds 3  # Give it time to start
        }
        Write-EnhancedLog "Opening document: $documentPath" -ForegroundColor Cyan
        $document = $qlikView.OpenDoc($documentPath, "", "", $false)
        
        if ($document) {
            if ($Reload) {
                Write-EnhancedLog "Reloading document..." -ForegroundColor Cyan
                $document.Reload($true, $false, $false)
            }
            Write-EnhancedLog "Document opened successfully" -ForegroundColor Green
        }
        else {
            Write-EnhancedLog "Failed to open document" -ForegroundColor Red
        }
        
        return @{
            QlikView = $qlikView
            Document = $document
        }
    }
    catch {
        Write-Error "Failed to start QlikView Desktop: $_"
        return $null
    }
}


Function Close-QVWDesktop {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$QVSession
    )
    
    try {
        if ($QVSession.Document) {
            $QVSession.Document.GetApplication().Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($QVSession.Document) | Out-Null
        }
        
        if ($QVSession.QlikView) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($QVSession.QlikView) | Out-Null
        }
        
        Write-EnhancedLog "QlikView desktop process closed." -ForegroundColor Green
    }
    catch {
        Write-Warning "Error closing QlikView: $_"
    }
}

Export-ModuleMember -Function Start-QVWDesktop, Close-QVWDesktop