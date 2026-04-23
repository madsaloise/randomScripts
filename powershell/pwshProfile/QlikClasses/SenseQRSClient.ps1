class QRSClient {
    [string]$BaseUrl
    [string]$XrfKey
    [hashtable]$Headers

    QRSClient([string]$senseServer) {
        if ($senseServer -notmatch '^https://') {
            $senseServer = "https://$senseServer"
        }
        
        $this.BaseUrl = "$senseServer/qrs"
        $this.XrfKey = $this.GenerateXrfKey()

        $this.Headers = @{
            "X-Qlik-Xrfkey" = $this.XrfKey
            "Content-Type" = "application/json"
        }
        $this.ConfigureSecurity()
        
        Write-EnhancedLog "Connected to Qlik Sense QRS: $senseServer" -ForegroundColor Green
    }
    # Init methods
    hidden [string] GenerateXrfKey() {
        $chars = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        $key = ""
        for ($i = 0; $i -lt 16; $i++) {
            $key += $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)]
        }
        return $key
    }
    hidden [void] ConfigureSecurity() {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
            Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
        }
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    hidden [string] BuildUri([string]$endpoint, [hashtable]$queryParams) {
        $uri = "$($this.BaseUrl)/$endpoint"
        
        $queryString = "xrfkey=$($this.XrfKey)"

        if ($queryParams -and $queryParams.Count -gt 0) {
            foreach ($key in $queryParams.Keys) {
                $value = $queryParams[$key]
                $queryString += "&$key=$([System.Uri]::EscapeDataString($value))"
            }
        }
        
        return "$uri`?$queryString"
    }

    #Opret invoke til standardcalls forneden
    [object] Invoke([string]$endpoint, [string]$method, [object]$body, [hashtable]$queryParams) {
        $uri = $this.BuildUri($endpoint, $queryParams)
        
        $params = @{
            Uri = $uri
            Method = $method
            Headers = $this.Headers
            UseDefaultCredentials = $true
        }
        
        if ($body) {
            if ($body -is [string]) {
                $params.Body = $body
            }
            else {
                $params.Body = ($body | ConvertTo-Json -Depth 10)
            }
        }
        
        try {
            $response = Invoke-RestMethod @params
            return $response
        }
        catch {
            $errorMessage = "QRS API Error on '$method $endpoint': $($_.Exception.Message)"
            if ($_.ErrorDetails.Message) {
                $errorMessage += "`nDetails: $($_.ErrorDetails.Message)"
            }
            throw $errorMessage
        }
    }

    # Methods
    [object] Get([string]$endpoint) {
        return $this.Invoke($endpoint, "GET", $null, $null)
    }

    [object] Get([string]$endpoint, [hashtable]$queryParams) {
        return $this.Invoke($endpoint, "GET", $null, $queryParams)
    }

    [object] Post([string]$endpoint, [object]$body) {
        return $this.Invoke($endpoint, "POST", $body, $null)
    }

    [object] Put([string]$endpoint, [object]$body) {
        return $this.Invoke($endpoint, "PUT", $body, $null)
    }

    [object] Delete([string]$endpoint) {
        return $this.Invoke($endpoint, "DELETE", $null, $null)
    }
    
    [void] Disconnect() {
        Write-Host "Disconnecting from QRS: $($this.BaseUrl)" -ForegroundColor Yellow
        $this.Headers = $null
        $this.XrfKey = $null
        $this.BaseUrl = $null
        Write-Host "QRS client disconnected" -ForegroundColor Green
    }
    
    #Liste over alle api kald
    [object] GetApiDescription() {
        return $this.Get("about/api/description", @{ format = "json"; extended = $true })
    }
}
