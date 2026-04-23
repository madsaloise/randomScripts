function Get-ADDirectories {
    <#
    .SYNOPSIS
        Gets Active Directory providers and available directories from QMS API
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER AllServices
        Array of all services to find the Directory Service Connector
    
    .OUTPUTS
        Hashtable containing AD provider and available directories
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [array]$AllServices
    )
    
    Write-EnhancedLog "Active Directory Configuration" -ForegroundColor Cyan
    
    $dscGUID = @($AllServices | Where-Object {$_.Type -eq "QlikViewDirectoryServiceConnector"}) | ForEach-Object { $_.ID }
    
    if (-not $dscGUID) {
        Write-EnhancedLog "(No Directory Service Connector found)" -ForegroundColor Yellow
        return @{
            DSProviders = $null
            ADProvider = $null
            AvailableDirectories = $null
        }
    }
    
    $dscResult = ($ApiClient.InvokeMethod("GetAvailableDSProviders", @{ dscID = $dscGUID})).DSProvider
    $adProvider = $dscResult | Where-Object {$_.Type -eq "ad"} 
    
    if ($adProvider) {
        Write-EnhancedLog "AD Provider found: $($adProvider.Name)"
        
        try {
            $availDirectories = $ApiClient.InvokeMethod("GetAvailableDirectories", @{dscID = $dscGUID; "type" = $adProvider.Type})
            Write-EnhancedLog "Available directories: $($availDirectories.string -join ', ')"
        }
        catch {
            Write-EnhancedLog "(Could not retrieve available directories: $($_.Exception.Message))" -ForegroundColor Yellow
            $availDirectories = $null
        }
    }
    else {
        Write-EnhancedLog "(No AD provider found)" -ForegroundColor Yellow
        $availDirectories = $null
    }
    
    return @{
        DSProviders = $dscResult
        ADProvider = $adProvider
        AvailableDirectories = $availDirectories
    }
}

Export-ModuleMember -Function Get-ADDirectories
