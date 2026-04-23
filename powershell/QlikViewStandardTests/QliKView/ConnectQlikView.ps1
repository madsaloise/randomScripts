
#InvokeMethod(<Method>, @{ param1 = "y", param2 = "x" }, [mandatory=false][bool]$returnFullResponse)

param(
    [Parameter(Mandatory=$false)]
    [string]$qmcHostTest,
    [Parameter(Mandatory=$false)]
    [string]$qmcHostProd,
    [Parameter(Mandatory=$false)]
    [string]$accessPointTest,
    [Parameter(Mandatory=$false)]
    [string]$accessPointProd,
    [Parameter(Mandatory=$false)]
    [string]$qlikTestFileShare,
    [Parameter(Mandatory=$false)]
    [string]$qlikProdFileShare,
    [Parameter(Mandatory=$false)]
    [string]$schedulerUri,
    [Parameter(Mandatory=$false)]
    [string]$QMSHost = $qmcHostTest, 
    [Parameter(Mandatory=$false)]
    [int]$QMSPort = 4799,
    [Parameter(Mandatory=$false)]
    [string]$InterfaceVersion = "IQMS9"
)

#Set variables depending on env
switch($QMSHost) {
    "$($qmcHostTest)" {
        $fileToOpen = "qvp://$($accessPointTest)/Opslagstabeller.qvw"
        $fileSharePath = "$($qlikTestFileShare)/QVTEST"
        $qmcTaskToRun = "Reload of SA\10_LOAD\10_SA_BUDGETID.qvw"
    } 
    "$($qmcHostProd)" {
        $fileToOpen = "qvp://$($accessPointProd)/Opslagstabeller.qvw"
        $fileSharePath = "$($qlikProdFileShare)\QVPROD"
        $qmcTaskToRun = "Prod - Reload of SA\10_LOAD\10_SA_BUDGETID.qvw"
    }        
}

$logPath = "$PSScriptRoot\Output\TestLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
if (-not (Test-Path "$PSScriptRoot\Output")) {
    New-Item -Path "$PSScriptRoot\Output" -ItemType Directory -Force | Out-Null
}
Start-EnhancedLog -LogPath $logPath

$modulePath = "$PSScriptRoot\Modules"

if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
        Write-EnhancedLog "Importing module: $($_.Name)" -ForegroundColor Cyan
        Import-Module $_.FullName -Force
    }
}
#. "$modulePath\ClientClass.ps1"


# ---------------------------------------------------------------
# Main script

try {
    $apiClient = [QMSClient]::new($QMSHost, $QMSPort, $InterfaceVersion)

    # Connectivity
    Write-EnhancedLog "Testing a ping against the QMC" -ForegroundColor Cyan
    try {
        $apiClient.InvokeMethod("Ping", @{})
        Write-EnhancedLog "Ping: Success" -ForegroundColor Green
    }
    catch {
        Write-EnhancedLog "Ping: Failed" -ForegroundColor Red
    }

    #Get services
    Write-EnhancedLog "Retrieving all services" -ForegroundColor Cyan
    $servicesResult = $apiClient.InvokeMethod("GetServices", @{ serviceTypes = "All" })
    $allServices = @($servicesResult.ServiceInfo)
    $serviceStatus = Get-ServiceStatus -ApiClient $apiClient -AllServices $allServices

    # License 
    Write-EnhancedLog "Retrieving License Server Status" -ForegroundColor Cyan
    $licenseStatus = $apiClient.CheckLicenseServerStatus("CheckLicenseServerStatus")
    Write-EnhancedLog "Status: $licenseStatus"

    Write-EnhancedLog "Retrieving Signed Key License validity" -ForegroundColor Cyan
    $licenseOverview = $apiClient.InvokeMethod("GetLicenseOverview",@{})
    Write-EnhancedLog "License overview:" -ForegroundColor Green
    if ($licenseOverview.Valid -match '^(.+?)/(.+?)$') {
        $fromDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
        $toDate = [DateTime]::ParseExact($matches[2], "yyyy-MM-dd", $null)
        Write-EnhancedLog "  From: $($fromDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green
        Write-EnhancedLog "  To:   $($toDate.ToString('yyyy-MM-dd'))" -ForegroundColor Green
    }
    else {
        Write-EnhancedLog "$($licenseOverview.Valid)" -ForegroundColor Green
    }


    <#AD Group and users#>
    Write-EnhancedLog "`nRetrieving AD directories and assigned users" -ForegroundColor Cyan
    $adData = Get-ADDirectories -ApiClient $apiClient -AllServices $allServices
    if($null -eq $($adData.AvailableDirectories)  ) { 
    Write-EnhancedLog "No AD directory found" -ForegroundColor Yellow
    } else {
        Write-EnhancedLog "AD directory found: $($adData.AvailableDirectories.string -join ', ')" -ForegroundColor Green
    }
    $assignedUsers = Get-AssignedUsers -ApiClient $apiClient

    #TaskInfo
    Write-EnhancedLog "`nRetrieving QDS tasks" -ForegroundColor Cyan
    $qdsTasks = Get-QDSTasks -ApiClient $apiClient

    # Service Settings
    Write-EnhancedLog "`nRetrieving service settings" -ForegroundColor Cyan
    $qdsSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewDistributionService"
    Write-EnhancedLog ($qdsSettings | Format-List | Out-String)
    $dscSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewDirectoryServiceConnector"
    Write-EnhancedLog ($dscSettings | Format-List | Out-String)
    $qvwSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewServer"
    Write-EnhancedLog ($qvwSettings | Format-List | Out-String)
    $qvwsSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewWebServer" 
    Write-EnhancedLog ($qvwsSettings | Format-List | Out-String)
    $qvprSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QVPR"
    Write-EnhancedLog ($qvprSettings | Format-List | Out-String)

    #Test run reload
    $runResult = Invoke-TaskWithMonitoring -ApiClient $apiClient -TaskName $qmcTaskToRun -PollInterval 5
    
    if ($runResult) {
        Write-EnhancedLog "`nTask completed successfully" -ForegroundColor Green

    }
    else {
        Write-EnhancedLog "`nTask failed" -ForegroundColor Red
    }
}
catch {
    Write-Error "An exception occurred: $_"
}

<#ServerObjects #>
Write-EnhancedLog "`nChecking server objects" -ForegroundColor Cyan
$serverObjects = Get-ServerObjects -ApiClient $apiClient
$serverTypes = $serverObjects | ForEach-Object {
    if ($_.SubType) {$_.SubType} else {$_.Type}
} | Group-Object | ForEach-Object {"$($_.Name) ($($_.Count))"}

Write-EnhancedLog "Unique object types found: $($serverTypes -join ', ')" -ForegroundColor Green


<#QLIKVIEW ACCESSPOINT TESTING#>
Write-EnhancedLog "`nTesting QlikView Desktop connectivity to accesspoint" -ForegroundColor Cyan



$qvSession = Start-QVWDesktop -documentPath $fileToOpen


Write-EnhancedLog "Looks good?" -ForegroundColor Yellow
$response = Read-Host "Continue? (y/n)"

if ($response -notmatch '^[yY]') {
    Write-EnhancedLog "QlikView document did not look correct" -ForegroundColor Red
    Close-QVWDesktop -QVSession $qvSession
    Stop-EnhancedLog
    Exit 1
}
Close-QVWDesktop -QVSession $qvSession
Write-EnhancedLog "Everything checked serverside" -ForegroundColor Green
Write-EnhancedLog "====================================================== `n" -ForegroundColor Green



Write-EnhancedLog "Secondary functions testing begins" -ForegroundColor Cyan

Write-EnhancedLog "Testing file share access.." -ForegroundColor Cyan
if (Test-Path -Path $fileSharePath) {
    Write-EnhancedLog "Fileshare $($fileSharePath) can be opened" -ForegroundColor Green    
} else {
    Write-EnhancedLog "Fileshare $($fileSharePath) cannot be opened" -ForegroundColor Red
}

$categoryName = "BI QlikView Distribution"
$taskName = "Distribuer QlikView Hotfix"

Write-EnhancedLog "Testing if scheduler task can be started. `nTask: $($taskName)." -ForegroundColor Cyan
$startSchedulerTask = Start-SchedulerTask -SchedulerUri $schedulerUri -CategoryName $categoryName -TaskName $taskName
if ($startSchedulerTask.Success) {
    Write-EnhancedLog "$($taskName) started!" -ForegroundColor Green
    Write-EnhancedLog "Polling for task completion..." -ForegroundColor Cyan
    $maxAttempts = 100
    $pollInterval = 2 
    $attempt = 0
    $taskCompleted = $false
    while ($attempt -lt $maxAttempts -and -not $taskCompleted) {
        Start-Sleep -Seconds $pollInterval
        $attempt++
        Write-EnhancedLog "Checking task status at $($attempt * $pollInterval) seconds..." -ForegroundColor Cyan
        $completionResult = Test-SchedulerTaskCompletion -SchedulerUri $schedulerUri -CategoryName $categoryName -TaskName $taskName -StartTime $startSchedulerTask.StartTime
        if ($completionResult.TaskCompleted) {
            $taskCompleted = $true
            Write-EnhancedLog "Task completed at $($completionResult.CompletedTime)" -ForegroundColor Green
        }
    }
    if (-not $taskCompleted) {
        Write-EnhancedLog "Task did not complete within the timeout period ($($maxAttempts * $pollInterval) seconds)" -ForegroundColor Yellow
    }
} else {
    Write-EnhancedLog "Failed to start scheduler task" -ForegroundColor Red
}


Write-EnhancedLog "`n=====================================" -ForegroundColor Cyan
Write-EnhancedLog "`nMANUAL CHECK AFTER COMPLETION" -ForegroundColor Cyan

Write-EnhancedLog "Please verify the following manually:" -ForegroundColor Yellow
Write-EnhancedLog "Open the QMC on $QMSHost and check if there are any errors flagged at the top of the webpage." -ForegroundColor Yellow
Write-EnhancedLog "Verify that an user (for example yourself) exists in the search engine of the QMC." -ForegroundColor Yellow
Write-EnhancedLog "Verify that $qmcTaskToRun has been executed" -ForegroundColor Yellow
Write-EnhancedLog "Check the QlikView AccessPoint to see if a document is listed and can be opened. Check if data looks OK too." -ForegroundColor Yellow
Write-EnhancedLog "Check the file share ($fileSharePath) to see if there are files present." -ForegroundColor Yellow
Write-EnhancedLog "Check the scheduler task history for $(taskName) to verify it has been ran." -ForegroundColor Yellow

Write-EnhancedLog "`nOnce you have verified these, please enter 'y' to continue." -ForegroundColor Yellow
$response = Read-Host "Continue? (y/n)"
if ($response -notmatch '^[yY]') {
    Write-EnhancedLog "Manual checks not completed" -ForegroundColor Red 
}   else {
    Write-EnhancedLog "Everything looks good!" -ForegroundColor Green
}
Write-EnhancedLog "====================================================== `n" -ForegroundColor Green


#End of script
Stop-EnhancedLog 

   