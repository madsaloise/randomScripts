
#InvokeMethod(<Method>, @{ param1 = "y", param2 = "x" }, [mandatory=false][bool]$returnFullResponse)

param(
    [string]$QMSHost        = $qmcHostTest, 
    [int]$QMSPort           = 4799,
    [string]$InterfaceVersion = "IQMS9"
)

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
. "$modulePath\ClientClass.ps1"


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
    $qdsSettings
    $dscSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewDirectoryServiceConnector"
    $dscSettings
    $qvwSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewServer"
    $qvwSettings
    $qvwsSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QlikViewWebServer" 
    $qvwsSettings
    $qvprSettings = Get-ServiceSettings -ApiClient $apiClient -serviceType "QVPR"
    $qvprSettings

    #Test run reload
    $runResult = Invoke-TaskWithMonitoring -ApiClient $apiClient -TaskName "Reload of SA\10_LOAD\10_SA_BUDGETID.qvw" -PollInterval 5
    
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


<#QLIKVIEW ACCESSPOINT TESTING#>
Write-EnhancedLog "`nTesting QlikView Desktop connectivity to accesspoint" -ForegroundColor Cyan

switch($QMSHost) {
    "qlikview-qmc-t.Server.net" {
        $fileToOpen = "qvp://$($qmcHostTest)/Opslagstabeller.qvw"
    } 
    "qlikview-qmc.Server.net" {
        $fileToOpen = "qvp://$($qmcHostProd)/Opslagstabeller.qvw"
    }        
}

$qvSession = Start-QVWDesktop -documentPath $fileToOpen


Write-EnhancedLog "Looks good?" -ForegroundColor Yellow
$response = Read-Host "Continue? (y/n)"

if ($response -notmatch '^[yY]') {
    Write-EnhancedLog "QlikView document did not look correct" -ForegroundColor Red
    Close-QVWDesktop -QVSession $qvSession
    Stop-EnhancedLog
    Exit 1
}

Write-EnhancedLog "Everything looks correct" -ForegroundColor Green
Close-QVWDesktop -QVSession $qvSession
Stop-EnhancedLog 

   