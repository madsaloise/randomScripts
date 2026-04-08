function Get-TaskByName {
    <#
    .SYNOPSIS
        Retrieves a QlikView task by name
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER TaskName
        The name of the task to retrieve (supports wildcards)
    
    .PARAMETER QdsID
        Optional: Specific QDS ID to search. If not provided, searches all QDS services.
    
    .OUTPUTS
        Task information object(s) matching the name
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [string]$QdsID
    )
    if ($QdsID) {
        $qdsServices = @([PSCustomObject]@{ ID = $QdsID })
    }
    else {
        $qdsResult = $ApiClient.InvokeMethod("GetServices", @{ serviceTypes = "QlikViewDistributionService" })
        $qdsServices = @($qdsResult.ServiceInfo)
        
        if (-not $qdsServices -or $qdsServices.Count -eq 0) {
            Write-EnhancedLog "No QDS services found" -ForegroundColor Yellow
            return $null
        }
    }
    $matchingTasks = @()
    
    foreach ($qds in $qdsServices) {
        try {
            $taskResult = $ApiClient.InvokeMethod("GetTasks", @{ qdsID = $qds.ID })
            $tasks = @($taskResult.TaskInfo)
            
            if ($tasks.Count -gt 0) {
                $matches = $tasks | Where-Object { $_.Name -like $TaskName }
                
                if ($matches) {
                    foreach ($match in $matches) {
                        $match | Add-Member -MemberType NoteProperty -Name "SourceQDS" -Value $qds.Name -Force
                        $match | Add-Member -MemberType NoteProperty -Name "SourceQDSID" -Value $qds.ID -Force
                    }
                    
                    $matchingTasks += $matches
                }
            }
        }
        catch {
            Write-EnhancedLog "Could not retrieve tasks from QDS: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    if ($matchingTasks.Count -eq 0) {
        Write-EnhancedLog "No tasks found matching: $TaskName" -ForegroundColor Yellow
        return $null
    }
    
    # Display task information
    foreach ($task in $matchingTasks) {
        Write-EnhancedLog "Task: $($task.Name)" -ForegroundColor Green
        Write-EnhancedLog "  ID: $($task.ID)"
        Write-EnhancedLog "  QDS: $($task.SourceQDS)"
        Write-EnhancedLog "  Enabled: $($task.Enabled)"
    }
    
    return $matchingTasks
}

function Get-TaskStatus {
    <#
    .SYNOPSIS
        Retrieves the current status of a QlikView task
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER TaskID
        The GUID of the task to check
    
    .PARAMETER Scope
        TaskStatusScope: "General", "Extended", "All", "DocumentInfo", "LastExecInfo", "NextExecInfo"
        Default: "All"
    
    .OUTPUTS
        Task status object with General and Extended status information
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskID,
        
        [Parameter(Mandatory=$false)]
        [string]$Scope = "All"
    )
    
    try {
        $result = $ApiClient.InvokeMethod("GetTaskStatus", [ordered]@{ 
            taskID = $TaskID
            scope = $Scope
        })
        return $result
    }
    catch {
        Write-EnhancedLog "Failed to get task status: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Invoke-TaskWithMonitoring {
    <#
    .SYNOPSIS
        Runs a QlikView task and monitors its execution until completion
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER TaskName
        The name of the task to run (supports wildcards)
    
    .PARAMETER PollInterval
        Seconds to wait between status checks (default: 5)
    
    .OUTPUTS
        Boolean - True if task completed successfully, False if failed
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        
        [Parameter(Mandatory=$false)]
        [int]$PollInterval = 5
    )
    
    # Kan ikke ID i hovedet så finder pba. navn
    Write-EnhancedLog "Searching for task: $TaskName" -ForegroundColor Cyan
    $tasks = Get-TaskByName -ApiClient $ApiClient -TaskName $TaskName
    
    if (-not $tasks) {
        Write-EnhancedLog "Task not found: $TaskName" -ForegroundColor Red
        return $false
    }
    
    $taskArray = @($tasks)
    if ($taskArray.Count -gt 1) {
        Write-EnhancedLog "`nMultiple tasks found. Select one to run:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $taskArray.Count; $i++) {
            Write-EnhancedLog "  $($i + 1). $($taskArray[$i].Name)"
        }
        $selection = Read-Host "Enter number"
        if ($selection -match '^\d+$') {
            $index = [int]$selection - 1
            if ($index -ge 0 -and $index -lt $taskArray.Count) {
                $TaskID = $taskArray[$index].ID
            }
            else {
                Write-EnhancedLog "Invalid selection" -ForegroundColor Red
                return $false
            }
        }
        else {
            Write-EnhancedLog "Invalid input" -ForegroundColor Red
            return $false
        }
    }
    else {
        $TaskID = $tasks.ID
    }
    
    try {       
        # Run task
        Write-EnhancedLog "Running task: '$TaskID'..." -ForegroundColor Cyan
        
        $ApiClient.InvokeMethod("RunTask", @{ taskID = $TaskID })
        Write-EnhancedLog "Task execution initiated. Monitoring status..." -ForegroundColor Green
        Start-Sleep -Seconds $PollInterval
        
        # Poll completion (waiting)
        Do {
            Start-Sleep -Seconds $PollInterval
            $taskStatus = Get-TaskStatus -ApiClient $ApiClient -TaskID $TaskID -Scope "All"
            
            if ($taskStatus -and $taskStatus.General) {
                $currentStatus = $taskStatus.General.Status
                Write-EnhancedLog "  Status: $currentStatus" -ForegroundColor Gray
            }
            else {
                Write-EnhancedLog "  Could not retrieve status, continuing to poll..." -ForegroundColor Yellow
            }
        } until ($taskStatus.General.Status -eq "Waiting" -or $taskStatus.General.Status -eq "Failed")
        
        if ($taskStatus.General.Status -eq "Waiting") {
            Write-EnhancedLog "Task '$TaskID' completed successfully." -ForegroundColor Green
            return $true
        }
        else {
            Write-EnhancedLog "Task '$TaskID' failed." -ForegroundColor Red
            if ($taskStatus.General.StatusMessage) {
                Write-EnhancedLog "Error: $($taskStatus.General.StatusMessage)" -ForegroundColor Red
            }
            return $false
        }
    }
    catch {
        Write-EnhancedLog "Error running task: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

Export-ModuleMember -Function Get-TaskByName, Invoke-TaskWithMonitoring
