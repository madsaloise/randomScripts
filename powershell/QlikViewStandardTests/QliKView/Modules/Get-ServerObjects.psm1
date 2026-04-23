function Get-ServerObjects {
    <#
    .SYNOPSIS
        Retrieves all server objects from all documents on a QlikView Server.
    
    .DESCRIPTION
        Gets the QlikView Server service, retrieves all user documents, and then
        fetches all server objects (collaboration objects) for each document.
    
    .PARAMETER ApiClient
        The QMS API client instance to use for the calls.
    
    .EXAMPLE
        $serverObjects = Get-ServerObjects -ApiClient $apiClient
        $serverObjects | Format-Table DocumentName, ObjectId, Type, OwnerName, Shared
    
    .OUTPUTS
        Returns an array of custom objects containing server object information with document context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$ApiClient
    )
    
    try {
        Write-EnhancedLog "Retrieving QlikView Server service..." -ForegroundColor Cyan
        $qvsResult = $ApiClient.InvokeMethod("GetServices", @{ serviceTypes = "QlikViewServer" })
        
        if (-not $qvsResult) {
            Write-EnhancedLog "No QlikView Server service found" -ForegroundColor Red
            return @()
        }
        $qvsServices = @($qvsResult.ServiceInfo)
        
        if ($qvsServices.Count -eq 0) {
            Write-EnhancedLog "No QlikView Server services available" -ForegroundColor Red
            return @()
        }
        
        $qvsService = $qvsServices[0]
        $qvsID = $qvsService.ID
        Write-EnhancedLog "Found QlikView Server: $($qvsService.Name) (ID: $qvsID)" -ForegroundColor Green
        Write-EnhancedLog "Retrieving user documents..." -ForegroundColor Cyan
        $documentsResult = $ApiClient.InvokeMethod("GetUserDocuments", @{ qvsID = $qvsID })
        
        if (-not $documentsResult) {
            Write-EnhancedLog "No documents found" -ForegroundColor Yellow
            return @()
        }
        $documents = @($documentsResult.DocumentNode)
        Write-EnhancedLog "Found $($documents.Count) documents" -ForegroundColor Green
        Write-EnhancedLog "Retrieving server objects from documents..." -ForegroundColor Cyan
        $allServerObjects = @()
        
        foreach ($doc in $documents) {
            $docName = $doc.Name
            try {
                $serverObjectsResult = $ApiClient.InvokeMethod("GetServerObjects", @{ 
                    qvsID = $qvsID
                    documentName = $docName 
                })
                if ($serverObjectsResult) {
                    $serverObjects = @($serverObjectsResult.ServerObject)
                    
                    if ($serverObjects.Count -gt 0) {
                        foreach ($obj in $serverObjects) {
                            if ($null -ne $obj.Id) {
                                $allServerObjects += [PSCustomObject]@{
                                    DocumentName = $docName
                                    ObjectId = $obj.Id
                                    Type = $obj.Type
                                    SubType = $obj.SubType
                                    OwnerName = $obj.OwnerName
                                    UtcModifyTime = $obj.UtcModifyTime
                                    Shared = $obj.Shared
                                    Description = $obj.Description
                                }    
                            }
                        }
                    }
                }
                else {
                    Write-EnhancedLog "No server objects found" -ForegroundColor Yellow
                }
            }
            catch {
                Write-EnhancedLog "Error retrieving server objects: $_" -ForegroundColor Red
            }
        }
        
        Write-EnhancedLog "`nTotal server objects found: $($allServerObjects.Count)" -ForegroundColor Cyan
        
        return $allServerObjects
    }
    catch {
        Write-Error "Failed to retrieve server objects: $_"
        throw
    }
}

Export-ModuleMember -Function Get-ServerObjects
