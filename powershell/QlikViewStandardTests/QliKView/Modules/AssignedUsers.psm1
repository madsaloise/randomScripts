function Get-AssignedUsers {
    <#
    .SYNOPSIS
        Gets assigned users with their license types.
    
    .DESCRIPTION
        Retrieves a list of all users with assigned licenses (Professional and Analyzer)
        and groups them by license type.
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER AdditionalFilter
        Optional filter for retrieving assigned users
    
    .PARAMETER ShowFullXml
        If specified, displays the full XML response from the API
    
    .PARAMETER UserFilter
        Optional filter to only show users matching this pattern (supports wildcards)
    
    .PARAMETER GroupByLicense
        If specified, groups output by license type. Default is true.
    
    .OUTPUTS
        Assignments object with user and license information
    
    .EXAMPLE
        Get-AssignedUsers -ApiClient $apiClient
        
    .EXAMPLE
        Get-AssignedUsers -ApiClient $apiClient -UserFilter "PROD\*"
        
    .NOTES
        Requires membership of local groups QlikView Management API and QlikView Administrator.
        Uses IQMS4 interface.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$false)]
        [string]$AdditionalFilter = "",
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowFullXml,
        
        [Parameter(Mandatory=$false)]
        [string]$UserFilter,
        
        [Parameter(Mandatory=$false)]
        [switch]$GroupByLicense
    )
    
    try {
        Write-EnhancedLog "`nRetrieving Assigned Users..." -ForegroundColor Cyan
        $parameters = @{
            additionalFilter = $AdditionalFilter
        }
        
        $response = $ApiClient.InvokeMethod("GetAssignedUsers", $parameters, $true)
        
        if ($ShowFullXml) {
            Write-EnhancedLog "`n=== FULL XML ENVELOPE ===" -ForegroundColor Magenta
            Write-EnhancedLog $response.OuterXml -ForegroundColor Gray
            Write-EnhancedLog "=== END FULL XML ===`n" -ForegroundColor Magenta
        }
        
        $resultNode = $response.Envelope.Body.GetAssignedUsersResponse.GetAssignedUsersResult
        
        if ($null -eq $resultNode) {
            Write-EnhancedLog "No assigned users returned" -ForegroundColor Yellow
            return $null
        }

        $assignments = @($resultNode.assignments.Assignment)
        
        if (-not $assignments -or $assignments.Count -eq 0) {
            Write-EnhancedLog "No user assignments found" -ForegroundColor Yellow
            return @()
        }
        
        if ($UserFilter) {
            $assignments = $assignments | Where-Object { $_.subject -like $UserFilter }
        }
        
        $professionalUsers = @($assignments | Where-Object { $_.type -eq "professional" })
        $analyzerUsers = @($assignments | Where-Object { $_.type -eq "analyzer" })
        $otherUsers = @($assignments | Where-Object { $_.type -ne "professional" -and $_.type -ne "analyzer" })
        
        Write-EnhancedLog "`n=== License Assignment Summary ===" -ForegroundColor Green
        Write-EnhancedLog "Total Assigned Users: $($assignments.Count)" -ForegroundColor Green
        Write-EnhancedLog "  Professional: $($professionalUsers.Count)" -ForegroundColor Cyan
        Write-EnhancedLog "  Analyzer:     $($analyzerUsers.Count)" -ForegroundColor Cyan
        if ($otherUsers.Count -gt 0) {
            Write-EnhancedLog "  Other:        $($otherUsers.Count)" -ForegroundColor Cyan
        }
        Write-EnhancedLog ""
        
        if ($GroupByLicense) {
            if ($professionalUsers.Count -gt 0) {
                Write-EnhancedLog "=== Professional License Users ($($professionalUsers.Count)) ===" -ForegroundColor Yellow
                foreach ($user in ($professionalUsers | Sort-Object subject)) {
                    Write-EnhancedLog "  $($user.subject)" -ForegroundColor White
                    if ($user.created) {
                        Write-EnhancedLog "    Assigned: $($user.created)" -ForegroundColor Gray
                    }
                }
                Write-EnhancedLog ""
            }
            
            if ($analyzerUsers.Count -gt 0) {
                Write-EnhancedLog "=== Analyzer License Users ($($analyzerUsers.Count)) ===" -ForegroundColor Yellow
                foreach ($user in ($analyzerUsers | Sort-Object subject)) {
                    Write-EnhancedLog "  $($user.subject)" -ForegroundColor White
                    if ($user.created) {
                        Write-EnhancedLog "    Assigned: $($user.created)" -ForegroundColor Gray
                    }
                }
                Write-EnhancedLog ""
            }
            if ($otherUsers.Count -gt 0) {
                Write-EnhancedLog "=== Other License Types ($($otherUsers.Count)) ===" -ForegroundColor Yellow
                foreach ($user in ($otherUsers | Sort-Object subject)) {
                    Write-EnhancedLog "  $($user.subject) - $($user.type)" -ForegroundColor White
                    if ($user.created) {
                        Write-EnhancedLog "    Assigned: $($user.created)" -ForegroundColor Gray
                    }
                }
                Write-EnhancedLog ""
            }
        }
        return @{
            Total = $assignments.Count
            Professional = $professionalUsers
            Analyzer = $analyzerUsers
            Other = $otherUsers
            All = $assignments
        }
    }
    catch {
        Write-Error "Failed to retrieve assigned users: $_"
        return $null
    }
}

Export-ModuleMember -Function Get-AssignedUsers
