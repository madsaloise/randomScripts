function Start-SchedulerTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchedulerUri,
        
        [Parameter(Mandatory = $true)]
        [string]$CategoryName,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    try {
        $startTime = Get-Date
        
        # Find links på forsiden
        $frontpage = Invoke-WebRequest -Uri $SchedulerUri -Method GET -UseDefaultCredentials -UseBasicParsing -SessionVariable session
        

        <# Find filtreret kategori #>
        $categoryHref = $frontpage.Links.Href | Where-Object { $_ -like "*$([System.Uri]::EscapeDataString($CategoryName))*" }
        
        if (-not $categoryHref) {
            throw "Category '$CategoryName' not found on scheduler page"
        }
        
        $categoryUrl = [System.Uri]::new([System.Uri]$SchedulerUri, $categoryHref).AbsoluteUri
        
        $taskPage = Invoke-WebRequest -Uri $categoryUrl -Method GET -UseDefaultCredentials -UseBasicParsing -WebSession $session
        

        <#Find task og start kørsel#>
        $taskNameEncoded = [System.Uri]::EscapeDataString($TaskName)
        $startHref = $taskPage.Links.Href | Where-Object { 
            $_ -like "*action=start*" -and $_ -like "*$taskNameEncoded*" 
        }
        
        if (-not $startHref) {
            throw "Task '$TaskName' not found in category '$CategoryName'"
        }
        
        $startUrl = [System.Uri]::new([System.Uri]$SchedulerUri, $startHref).AbsoluteUri
        
        $startResponse = Invoke-WebRequest -Uri $startUrl -Method GET -UseDefaultCredentials -UseBasicParsing -WebSession $session
        
        return [PSCustomObject]@{
            StatusCode = $startResponse.StatusCode
            Content = $startResponse.Content
            Success = ($startResponse.StatusCode -eq 200)
            StartTime = $startTime
        }
    }
    catch {
        Write-Error "Failed to start scheduler task: $_"
        throw
    }
}

function Test-SchedulerTaskCompletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SchedulerUri,
        
        [Parameter(Mandatory = $true)]
        [string]$CategoryName,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartTime
    )
    
    try {
        $frontpage = Invoke-WebRequest -Uri $SchedulerUri -Method GET -UseDefaultCredentials -UseBasicParsing -SessionVariable session
        
        $categoryHref = $frontpage.Links.Href | Where-Object { $_ -like "*$([System.Uri]::EscapeDataString($CategoryName))*" }
        
        if (-not $categoryHref) {
            throw "Category '$CategoryName' not found on scheduler page"
        }
        
        $categoryUrl = [System.Uri]::new([System.Uri]$SchedulerUri, $categoryHref).AbsoluteUri
        $taskPage = Invoke-WebRequest -Uri $categoryUrl -Method GET -UseDefaultCredentials -UseBasicParsing -WebSession $session
        
        $taskNameEncoded = [System.Uri]::EscapeDataString($TaskName)
        $historyHref = $taskPage.Links.Href | Where-Object { 
            $_ -like "*action=history*" -and $_ -like "*$taskNameEncoded*" 
        }
        
        if (-not $historyHref) {
            throw "History link for task '$TaskName' not found"
        }
        
        $historyUrl = [System.Uri]::new([System.Uri]$SchedulerUri, $historyHref).AbsoluteUri
        $historyResponse = Invoke-WebRequest -Uri $historyUrl -Method GET -UseDefaultCredentials -UseBasicParsing -WebSession $session
        $historyContent = $historyResponse.Content
        

        $taskCompleted = $false
        $completedTime = $null
        
        $rows = $historyContent -split '</tr>'
        
        foreach ($row in $rows) {
            if ($row -notmatch '<td>') { continue }
            
            $cells = [regex]::Matches($row, '<td>(.*?)</td>') | ForEach-Object { $_.Groups[1].Value }
            
            if ($cells.Count -ge 2) {
                $timeCreatedStr = $cells[0]
                $taskDisplayName = $cells[1]
                if ($taskDisplayName -eq 'Task completed') {
                    try {
                        $timeCreated = [DateTime]::ParseExact($timeCreatedStr, 'dd-MM-yyyy HH:mm:ss', $null)
                        
                        if ($StartTime) {
                            if ($timeCreated -gt $StartTime) {
                                $taskCompleted = $true
                                $completedTime = $timeCreated
                                break
                            }
                        }
                        else {
                            $taskCompleted = $true
                            $completedTime = $timeCreated
                            break
                        }
                    }
                    catch {
                        continue
                    }
                }
            }
        }
        
        return [PSCustomObject]@{
            TaskCompleted = $taskCompleted
            CompletedTime = $completedTime
            HistoryContent = $historyContent
            StatusCode = $historyResponse.StatusCode
        }
    }
    catch {
        Write-Error "Failed to check scheduler task completion: $_"
        throw
    }
}

Export-ModuleMember -Function Start-SchedulerTask, Test-SchedulerTaskCompletion