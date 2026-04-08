function Get-ServiceStatus {
    <#
    .SYNOPSIS
        Gets service statuses and health information from QMS API
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER AllServices
        Array of all services
    
    .OUTPUTS
        Hashtable containing service status
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [array]$AllServices
    )
    
    Write-EnhancedLog "Service Statuses" -ForegroundColor Cyan
    
    $allServiceIds = @($AllServices | ForEach-Object { $_.ID })
    $statusResult = $ApiClient.InvokeMethod("GetServiceStatuses", @{ serviceIDs = $allServiceIds })
    $statuses = @($statusResult.ServiceStatus)

    $allServicesOK = $true
    $allMembersRunning = $true
    $statusIssues = @()
    
    foreach ($status in $statuses) {
        Write-EnhancedLog " - $($status.Name)"
        if ($status.MemberStatusDetails) {
            $members = @($status.MemberStatusDetails.ServiceStatusDetail)
            foreach ($member in $members) {
                Write-EnhancedLog "      * Type: $($status.ServiceType) - Host: $($member.Host) - Status: $($member.Status) - $($member.Message.string)"
                if ($member.Status -ne "OK") {
                    $allServicesOK = $false
                    $statusIssues += "Service: $($status.Name), Host: $($member.Host), Status: $($member.Status)"
                }
                
                if ($member.Message.string -notmatch "Running" -and $member.Message.string -notmatch $null) {
                    $allMembersRunning = $false
                    $statusIssues += "Service: $($status.Name), Host: $($member.Host), Message: $($member.Message.string -join ', ')"
                }
            }
        }
    }
    
    return @{
        Statuses = $statuses
        AllServicesOK = $allServicesOK
        AllMembersRunning = $allMembersRunning
        StatusIssues = $statusIssues
    }
}

Export-ModuleMember -Function Get-ServiceStatus
