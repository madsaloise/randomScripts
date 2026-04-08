function Get-QDSTasks {
    <#
    .SYNOPSIS
        Gets QlikView Distribution Services and their tasks
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .OUTPUTS
        Hashtable containing tasks information
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient
    )
    
    Write-EnhancedLog "QlikView Distribution Services & Tasks" -ForegroundColor Cyan
    
    $qdsResult = $ApiClient.InvokeMethod("GetServices", @{ serviceTypes = "QlikViewDistributionService" })
    $qdsServices = @($qdsResult.ServiceInfo)
    $allTasks = @()
    
    if (-not $qdsServices -or $qdsServices.Count -eq 0) {
        Write-EnhancedLog "(No QDS services found)" -ForegroundColor Yellow
    }
    else {
        foreach ($qds in $qdsServices) {
            Write-EnhancedLog " - $($qds.Name) (ID: $($qds.ID))"
            
            try {
                $taskResult = $ApiClient.InvokeMethod("GetTasks", @{ qdsID = $qds.ID })
                $tasks = @($taskResult.TaskInfo)
                
                if ($tasks.Count -gt 0) {
                    Write-EnhancedLog "Found $($tasks.Count) tasks" -ForegroundColor Green
                    $allTasks += $tasks
                }
                else {
                    Write-EnhancedLog "(No tasks found)" -ForegroundColor Yellow
                }
            }
            catch {
                Write-EnhancedLog "(Could not retrieve tasks: $($_.Exception.Message))" -ForegroundColor Yellow
            }
        }
    }
    
    return @{
        QDSServices = $qdsServices
        Tasks = $allTasks
    }
}

Export-ModuleMember -Function Get-QDSTasks
