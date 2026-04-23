param(
    [Parameter(Mandatory=$false)]
    [string]$SenseServer = $senseHubTest
)

$logPath = "$PSScriptRoot\Output\SenseTestLog_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
if (-not (Test-Path "$PSScriptRoot\Output")) {
    New-Item -Path "$PSScriptRoot\Output" -ItemType Directory -Force | Out-Null
}
Start-EnhancedLog -LogPath $logPath

$modulePath = "$PSScriptRoot\Modules"

#. "$modulePath\QRSClient.ps1"

if (Test-Path $modulePath) {
    Get-ChildItem -Path $modulePath -Filter "*.psm1" | ForEach-Object {
        Write-EnhancedLog "Importing module: $($_.Name)" -ForegroundColor Cyan
        Import-Module $_.FullName -Force
    }
}

# ---------------------------------------------------------------
# Main script

try {
    $client = [QRSClient]::new($SenseServer)

    Write-EnhancedLog "Testing connection to Qlik Sense..." -ForegroundColor Cyan
    try {
        $about = $client.GET("about")
        Write-EnhancedLog "Connection successful!" -ForegroundColor Green
        Write-EnhancedLog "Qlik Sense Version: $($about.buildVersion)" -ForegroundColor Green
    }
    catch {
        Write-EnhancedLog "Connection failed: $_" -ForegroundColor Red
        throw
    }


    # license information
    $license = $client.Get("license")
    Write-EnhancedLog "  Is Expired: $($license.isExpired)" -ForegroundColor $(if ($license.isExpired) { "Red" } else { "Green" })

    if ($license.keyDetails) {
        Write-EnhancedLog "`nLicense Validity:" -ForegroundColor Cyan
        if ($license.keyDetails -match 'Valid From:\s*(\d{4}-\d{2}-\d{2})') {
            $validFrom = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
            Write-EnhancedLog "  Valid From: $($validFrom.ToString('yyyy-MM-dd'))" -ForegroundColor Green
        }
        if ($license.keyDetails -match 'Valid To:\s*(\d{4}-\d{2}-\d{2})') {
            $validTo = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
            Write-EnhancedLog "  Valid To: $($validTo.ToString('yyyy-MM-dd'))" -ForegroundColor Green
        
        }
    }
    else {
        Write-EnhancedLog "No key details available" -ForegroundColor Yellow
    }


    Write-EnhancedLog "`nRetrieving apps..." -ForegroundColor Cyan
    $apps = $client.Get("app")
    Write-EnhancedLog "Found $($apps.Count) apps" -ForegroundColor Green
    
    foreach ($app in $apps) {
        Write-EnhancedLog "  - $($app.name) (ID: $($app.id))" -ForegroundColor White
    }

    Write-EnhancedLog "`nRetrieving streams..." -ForegroundColor Cyan
    $streams = $client.Get("stream")
    Write-EnhancedLog "Found $($streams.Count) streams" -ForegroundColor Green
    
    foreach ($stream in $streams) {
        Write-EnhancedLog "  - $($stream.name)" -ForegroundColor White
    }
    Write-EnhancedLog "`nRetrieving reload tasks..." -ForegroundColor Cyan
    $reloadTasks = $client.Get("reloadtask/full")
    Write-EnhancedLog "Found $($reloadTasks.Count) reload tasks" -ForegroundColor Green
    
    foreach ($task in $reloadTasks) {
        Write-EnhancedLog "  - $($task.name) (Enabled: $($task.enabled))" -ForegroundColor White
    }

    <#Service status#>
    $serviceStatusMap = @{
        0 = "Initializing"
        1 = "CertificatesNotInstalled"
        2 = "Running"
        3 = "NoCommunication"
        4 = "Disabled"
        5 = "Unknown"
    }
    $serviceTypeMap = @{
        0 = "Repository"
        1 = "Proxy"
        2 = "Scheduler"
        3 = "Engine"
        4 = "AppMigration"
        5 = "Printing"
    }

    $serviceStatus = $client.Get("servicestatus/full")

    Write-EnhancedLog "`nService Status:" -ForegroundColor Cyan
    foreach ($service in $serviceStatus) {
        $color = if ($serviceStatusMap[$service.serviceState] -eq "Running") { "Green" } else { "Red" }
        Write-EnhancedLog "$($serviceTypeMap[$service.serviceType]): $($serviceStatusMap[$service.serviceState])" -ForegroundColor $color
    }
    <#Data connections#>
    $dataConnections = $client.Get("dataconnection/full")
    Write-EnhancedLog "`nData Connections: $($dataConnections.Count)" -ForegroundColor Cyan
    foreach ($conn in $dataConnections) {
        Write-EnhancedLog "$($conn.name) - Type: $($conn.type)"
        if ($conn.connectionstring -notmatch 'CUSTOM CONNECT') {
            Write-EnhancedLog "Path: $($conn.connectionstring)" -ForegroundColor Yellow
        }
    }
    <#Content libraries#>
    $contentLibraries = $client.Get("contentlibrary/full")
    Write-EnhancedLog "`nContent libraries: $($contentLibraries.Count)" -ForegroundColor Cyan
    foreach ($content in $contentLibraries) {
        Write-EnhancedLog "$($content.name) - Type: $($content.type)" -ForegroundColor Yellow
        foreach ($ref in $content.references) {
            Write-EnhancedLog $($ref.dataLocation) 
        }
    }
}
catch {
    Write-Error "An exception occurred: $_"
}



Stop-EnhancedLog