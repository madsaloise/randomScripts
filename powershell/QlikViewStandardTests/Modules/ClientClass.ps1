class QMSClient {

    [string]$BaseUrl
    [string]$InterfaceVersion
    [string]$ServiceKey

    QMSClient([string]$qmsHost, [int]$qmsPort, [string]$iface) {
        $this.BaseUrl          = "http://${qmsHost}:${qmsPort}/QMS/Service"
        $this.InterfaceVersion = $iface
        $this.ServiceKey       = ""

        # Init med service key, skal injectes i fremtidige kald
        $this.ServiceKey = $this.GetTimeLimitedServiceKey()
        Write-EnhancedLog "Connected using $iface. Service key: $($this.ServiceKey)"
    }
    #Starter en client
    [xml] Invoke([string]$operation, [string]$innerXml) {

        $soapAction = Get-SoapAction -iface $this.InterfaceVersion -operation $operation
        $ns = Get-XmlNamespace -iface $this.InterfaceVersion

        $client = New-Object System.Net.WebClient
        $client.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
        $client.Headers.Add("Content-Type", "text/xml; charset=utf-8")
        $client.Headers.Add("SOAPAction", "`"$soapAction`"")

        $key = if ($this.ServiceKey) { $this.ServiceKey } else { "" }
        $client.Headers.Add("X-Service-Key", $key)

        $envelope = @"
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
               xmlns:pix="$ns">
  <soap:Body>
    <pix:$operation>
      $innerXml
    </pix:$operation>
  </soap:Body>
</soap:Envelope>
"@
        try {
            $response = $client.UploadString($this.BaseUrl, "POST", $envelope)
            return [xml]$response
        }
        catch [System.Net.WebException] {
            $stream  = $_.Exception.Response.GetResponseStream()
            $reader  = New-Object System.IO.StreamReader($stream)
            $detail  = $reader.ReadToEnd()
            throw "SOAP fault on '$operation':`n$detail"
        }
    }

    # GetTimeLimitedServiceKey — bruges til connection
    # Reference: https://help.qlik.com/pt-PT/qlikview-developer/12.1/apis/QMS%20API/html/M_PIX_Services_V12_IQMS_GetTimeLimitedServiceKey.htm

    hidden [string] GetTimeLimitedServiceKey() {
        $response = $this.Invoke("GetTimeLimitedServiceKey", "")
        return $response.Envelope.Body.GetTimeLimitedServiceKeyResponse.GetTimeLimitedServiceKeyResult
    }

    <# InvokeMethod
     Returns the result element directly (Envelope.Body.FirstChild.FirstChild) (fits around 80% of api calls)
     Set returnFullResponse=$true for full envelope
    #>
    [object] InvokeMethod([string]$methodName, [hashtable]$parameters) {
        return $this.InvokeMethod($methodName, $parameters, $false)
    }
    
    [object] InvokeMethod([string]$methodName, [hashtable]$parameters, [bool]$returnFullResponse) {
        $innerXml = ""
        foreach ($key in $parameters.Keys) {
            $value = $parameters[$key]
            if ($value -is [array]) {
                $innerXml += "<pix:$key>"
                foreach ($item in $value) {
                    $innerXml += "<a:guid xmlns:a=`"http://schemas.microsoft.com/2003/10/Serialization/Arrays`">$item</a:guid>"
                }
                $innerXml += "</pix:$key>"
            }
            else {
                $innerXml += "<pix:$key>$value</pix:$key>"
            }
        }
        $response = $this.Invoke($methodName, $innerXml)
        
        if ($returnFullResponse) {
            return $response
        }
        else {
            # Ligner ret standard output fra API'et
            return $response.Envelope.Body.FirstChild.FirstChild
        }
    }


    [array] CheckLicenseServerStatus([string]$param) {
        $response = $this.InvokeMethod("CheckLicenseServerStatus", @{}, $true)
        $result = $response.Envelope.Body.CheckLicenseServerStatusResponse.CheckLicenseServerStatusResult
        return @($result)
    }
    <#
    Calling InvokeMethod when base method does not fit the standard pattern:
        [array] NewMethod([string]$param) {
            $response = $this.InvokeMethod("GetNewMethod", @{ paramName = $param })
            $result = $response.Envelope.Body.GetNewMethodResponse.GetNewMethodResult.Items
            return @($result)
        }
    #>
}