function Connect-QlikView {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$QmsHost,
        
        [Parameter(Mandatory = $false)]
        [int]$QmsPort = 4799,
        
        [Parameter(Mandatory = $false)]
        [string]$InterfaceVersion = "IQMS"
    )
    
    $scriptPath = "$PSScriptRoot\QlikClasses"
    $qvClientPath = Join-Path $scriptPath "QlikViewClient.ps1"
    
    if (-not (Test-Path $qvClientPath)) {
        throw "QlikViewClient.ps1 not found at: $qvClientPath"
    }
    
    . $qvClientPath

    return [QMSClient]::new($QmsHost, $QmsPort, $InterfaceVersion)
}

function Connect-SenseQRS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SenseServer
    )
    
    $scriptPath = "$PSScriptRoot\QlikClasses"
    $qrsClientPath = Join-Path $scriptPath "SenseQRSClient.ps1"
    
    if (-not (Test-Path $qrsClientPath)) {
        throw "SenseQRSClient.ps1 not found at: $qrsClientPath"
    }

    . $qrsClientPath

    return [QRSClient]::new($SenseServer)
}

function Connect-SenseEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SenseServer,
        
        [Parameter(Mandatory = $false)]
        [string]$VirtualProxy = "",
        
        [Parameter(Mandatory = $false)]
        [string]$AppId = ""
    )
    
    $scriptPath = "$PSScriptRoot\QlikClasses"
    $engineClientPath = Join-Path $scriptPath "SenseEngineClient.ps1"
    
    if (-not (Test-Path $engineClientPath)) {
        throw "SenseEngineClient.ps1 not found at: $engineClientPath"
    }

    . $engineClientPath

    if ($AppId) {
        return [QlikEngineClient]::new($SenseServer, $VirtualProxy, $AppId)
    } else {
        return [QlikEngineClient]::new($SenseServer, $VirtualProxy)
    }
}


Export-ModuleMember -Function Connect-QlikView, Connect-SenseQRS, Connect-SenseEngine
