class QlikApp {
    hidden [QlikEngineClient]$Engine
    [string]$AppId
    [int]$Handle

    QlikApp([QlikEngineClient]$engine, [string]$appId, [int]$handle) {
        $this.Engine = $engine
        $this.AppId = $appId
        $this.Handle = $handle
    }

    # Core
    [object] InvokeMethod([string]$method, [object]$params) {
        return $this.Engine.InvokeMethod($method, $params, $this.Handle)
    }

    # Specifikke metoder
    [object] GetAppProperties() {
        $result = $this.InvokeMethod("GetAppProperties", @())
        return $result.qProp
    }

    [string] GetScript() {
        $result = $this.InvokeMethod("GetScript", @())
        return $result.qScript
    }

    [void] SetScript([string]$script) {
        $this.InvokeMethod("SetScript", @($script)) | Out-Null
        Write-Host "Script updated" -ForegroundColor Green
    }

    hidden [object] GetList([hashtable]$definition) {
        $sessionObj = $this.InvokeMethod("CreateSessionObject", @($definition))
        $objHandle = $sessionObj.qReturn.qHandle
        
        $layout = $this.Engine.InvokeMethod("GetLayout", @(), $objHandle)
        
        if ($layout.qLayout.qAppObjectList) { return $layout.qLayout.qAppObjectList.qItems }
        if ($layout.qLayout.qVariableList) { return $layout.qLayout.qVariableList.qItems }
        if ($layout.qLayout.qDimensionList) { return $layout.qLayout.qDimensionList.qItems }
        if ($layout.qLayout.qMeasureList) { return $layout.qLayout.qMeasureList.qItems }
        if ($layout.qLayout.qBookmarkList) { return $layout.qLayout.qBookmarkList.qItems }
        if ($layout.qLayout.qFieldList) { return $layout.qLayout.qFieldList.qItems }
        
        return @()
    }

    [object] GetSheets() {
        $def = @{
            qInfo = @{ qType = "SheetList" }
            qAppObjectListDef = @{
                qType = "sheet"
                qData = @{ title = "/qMetaDef/title" }
            }
        }
        return $this.GetList($def)
    }

    [object] GetVariables() {
        $def = @{
            qInfo = @{ qType = "VariableList" }
            qVariableListDef = @{
                qType = "variable"
                qShowReserved = $true
                qShowConfig = $true
            }
        }
        
        $items = $this.GetList($def)
        $variables = @()
        
        foreach ($item in $items) {
            try {
                $varResult = $this.InvokeMethod("GetVariableById", @($item.qInfo.qId))
                $objHandle = $varResult.qReturn.qHandle
                $props = $this.Engine.InvokeMethod("GetProperties", @(), $objHandle)
                
                $props | Add-Member -NotePropertyName "qIsScriptCreated" -NotePropertyValue $item.qIsScriptCreated -Force
                $props | Add-Member -NotePropertyName "qIsReserved" -NotePropertyValue $item.qIsReserved -Force
                $props | Add-Member -NotePropertyName "qIsConfig" -NotePropertyValue $item.qIsConfig -Force
                
                $variables += $props
            } catch {
                Write-Warning "Could not get properties for variable $($item.qInfo.qId): $_"
                $variables += $item
            }
        }
        
        return $variables
    }

    [object] GetDimensions() {
        $def = @{
            qInfo = @{ qType = "DimensionList" }
            qDimensionListDef = @{ qType = "dimension" }
        }
        
        $items = $this.GetList($def)
        $dimensions = @()
        
        foreach ($item in $items) {
            try {
                $dimResult = $this.InvokeMethod("GetDimension", @($item.qInfo.qId))
                $objHandle = $dimResult.qReturn.qHandle
                $props = $this.Engine.InvokeMethod("GetProperties", @(), $objHandle)
                $dimensions += $props
            } catch {
                Write-Warning "Could not get properties for dimension $($item.qInfo.qId): $_"
                $dimensions += $item
            }
        }
        
        return $dimensions
    }

    [object] GetMeasures() {
        $def = @{
            qInfo = @{ qType = "MeasureList" }
            qMeasureListDef = @{ qType = "measure" }
        }
        
        $items = $this.GetList($def)
        $measures = @()
        
        foreach ($item in $items) {
            try {
                $measResult = $this.InvokeMethod("GetMeasure", @($item.qInfo.qId))
                $objHandle = $measResult.qReturn.qHandle
                $props = $this.Engine.InvokeMethod("GetProperties", @(), $objHandle)
                $measures += $props
            } catch {
                Write-Warning "Could not get properties for measure $($item.qInfo.qId): $_"
                $measures += $item
            }
        }
        
        return $measures
    }

    [object] GetFields() {
        $def = @{
            qInfo = @{ qType = "FieldList" }
            qFieldListDef = @{ qShowSystem = $true }
        }
        return $this.GetList($def)
    }

    [object] ExtractData() {
        Write-Host "`nExtracting App: $($this.AppId)" -ForegroundColor Cyan

        $properties = $this.GetAppProperties()
        Write-Host "Retrieved properties" -ForegroundColor Green

        $script = $this.GetScript()
        Write-Host "Retrieved script" -ForegroundColor Green

        $sheets = $this.GetSheets()
        Write-Host "($($sheets.Count) sheets)" -ForegroundColor Green

        $variables = $this.GetVariables()
        Write-Host "($($variables.Count) variables)" -ForegroundColor Green

        $dimensions = $this.GetDimensions()
        Write-Host "($($dimensions.Count) dimensions)" -ForegroundColor Green

        $measures = $this.GetMeasures()
        Write-Host "($($measures.Count) measures)" -ForegroundColor Green

        $fields = $this.GetFields()
        Write-Host "($($fields.Count) fields)" -ForegroundColor Green
        
        $data = @{
            appId = $this.AppId
            properties = $properties
            script = $script
            sheets = $sheets
            variables = $variables
            dimensions = $dimensions
            measures = $measures
            fields = $fields
            extractedAt = (Get-Date).ToString("o")
        }
        
        Write-Host "`nExtraction complete!" -ForegroundColor Green
        
        return $data
    }
}

class QlikEngineClient {
    [string]$HostName
    [string]$VirtualProxy
    [System.Net.WebSockets.ClientWebSocket]$WebSocket
    [int]$MessageIdCounter
    [bool]$IsConnected

    QlikEngineClient([string]$hostname, [string]$virtualProxy) {
        $this.HostName = $hostname
        $this.VirtualProxy = if ($virtualProxy -and -not $virtualProxy.StartsWith('/')) { "/$virtualProxy" } else { $virtualProxy }
        $this.MessageIdCounter = 0
        $this.IsConnected = $false
        
        $this.Connect()
    }

    #Connection
    hidden [void] Connect() {
        Write-Host "=== Connecting to Qlik Engine ===" -ForegroundColor Cyan
        Write-Host "Server: $($this.HostName)"
        Write-Host "Virtual Proxy: $(if ($this.VirtualProxy) { $this.VirtualProxy } else { '(central - no prefix)' })"
        Write-Host "Auth: Windows"
        Write-Host ""

        # session cookie
        Write-Host "Authenticating..." -NoNewline
        $sessionCookie = $this.GetSessionCookie()
        Write-Host " OK" -ForegroundColor Green

        #Connect  to engineData
        Write-Host "Opening WebSocket connection..." -NoNewline
        $this.ConnectWebSocket($sessionCookie)
        Write-Host " Connected" -ForegroundColor Green
        
        $this.IsConnected = $true
    }

    hidden [object] GetSessionCookie() {
        Add-Type -AssemblyName "System.Net.Http"

        $uri = "https://$($this.HostName)"
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.UseDefaultCredentials = $true
        $handler.CookieContainer = New-Object System.Net.CookieContainer
        $client = New-Object System.Net.Http.HttpClient($handler)
        $client.DefaultRequestHeaders.Add("X-Qlik-xrfkey", "ABCDEFG123456789")
        $client.DefaultRequestHeaders.Add("User-Agent", "Windows")
        try {
            $response = $client.GetAsync($uri).Result
        } catch {
            Write-Host $_
        }

        $cookies = $handler.CookieContainer.GetCookies($uri)
        $sessionCookie = $cookies["X-Qlik-Session"]
        if ($sessionCookie) {
            Write-Verbose "Session Cookie retrieved: $($sessionCookie.Name) - $($sessionCookie.Value)"
        }
        return $sessionCookie
    }

    hidden [void] ConnectWebSocket([object]$sessionCookie) {
        # always engineData on global
        $wsUri = "wss://$($this.HostName)$($this.VirtualProxy)/app/engineData"
        
        Write-Verbose "WebSocket URI: $wsUri"

        $this.WebSocket = New-Object System.Net.WebSockets.ClientWebSocket
        $this.WebSocket.Options.UseDefaultCredentials = $true

        if ($sessionCookie) {
            try {
                $cookieValue = "$($sessionCookie.Name)=$($sessionCookie.Value)"
                $this.WebSocket.Options.SetRequestHeader('Cookie', $cookieValue)
                Write-Verbose "Added session cookie: $($sessionCookie.Name)"
            } catch {
                Write-Verbose "Could not add cookie header: $_"
            }
        }
        
        $uri = [System.Uri] $wsUri
        try {
            $connectTask = $this.WebSocket.ConnectAsync($uri, [System.Threading.CancellationToken]::None)
            $connectTask.Wait()
        } catch {
            $errorMsg = "Failed to connect: $_`n"
            $errorMsg += "Troubleshooting tips:`n"
            $errorMsg += "  - Verify the server is accessible: https://$($this.HostName)$($this.VirtualProxy)/hub/`n"
            $errorMsg += "  - Check that your Windows user has access to Qlik Sense`n"
            $errorMsg += "  - Ensure the origin is whitelisted in QMC Virtual Proxy settings"
            throw $errorMsg
        }
    }

    [void] Disconnect() {
        if ($this.IsConnected -and $this.WebSocket) {
            Write-Host "Closing WebSocket..." -ForegroundColor Yellow
            try {
                $closeTask = $this.WebSocket.CloseAsync(
                    [System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure,
                    "Done",
                    [Threading.CancellationToken]::None
                )
                $closeTask.Wait()
                $this.IsConnected = $false
                Write-Host "WebSocket closed." -ForegroundColor Green
            } catch {
                Write-Warning "Error closing WebSocket: $_"
            }
        }
    }

    hidden [void] SendJsonRpc([int]$id, [string]$method, [object]$params, [int]$handle) {
        $payload = @{
            jsonrpc = "2.0"
            id      = $id
            method  = $method
            handle  = $handle
            params  = $params
        } | ConvertTo-Json -Depth 10 -Compress

        Write-Verbose "Sending -> $method (handle: $handle)"

        $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
        $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)

        $sendTask = $this.WebSocket.SendAsync(
            $segment,
            [System.Net.WebSockets.WebSocketMessageType]::Text,
            $true,
            [Threading.CancellationToken]::None
        )
        $sendTask.Wait()
    }

    hidden [string] ReceiveEngineMessage() {
        $buffer = New-Object byte[] 8192
        $message = ""
        $result = $null
        
        do {
            $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
            $result = $this.WebSocket.ReceiveAsync($segment, [Threading.CancellationToken]::None).Result

            $message += [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
        } while (-not $result.EndOfMessage)
        
        return $message
    }

    hidden [object] GetResponseById([int]$id) {
        $timeout = 0
        $maxIterations = 1000
        
        while ($timeout -lt $maxIterations) {
            $raw = $this.ReceiveEngineMessage()
            try {
                $msg = $raw | ConvertFrom-Json
            } catch {
                $timeout++
                continue
            }
            if ($null -eq $msg.id) {
                Write-Verbose "Received Engine event: $($msg.method)"
                $timeout++
                continue
            }
            if ($msg.id -eq $id) {
                return $msg
            }
            $timeout++
        }
        throw "Timeout waiting for response with id: $id"
    }

    [object] InvokeMethod([string]$method, [object]$params) {
        return $this.InvokeMethod($method, $params, -1)
    }

    [object] InvokeMethod([string]$method, [object]$params, [int]$handle) {
        if (-not $this.IsConnected) {
            throw "WebSocket is not connected. Please reconnect."
        }
        #Venter til at vi får rigtigt response, id skal matche
        $this.MessageIdCounter++
        $id = $this.MessageIdCounter

        $this.SendJsonRpc($id, $method, $params, $handle)
        $response = $this.GetResponseById($id)

        if ($response.error) {
            throw "Engine API Error: $($response.error.message) (Code: $($response.error.code))"
        }

        return $response.result
    }

    [QlikApp] OpenApp([string]$appId) {
        $result = $this.InvokeMethod("OpenDoc", @($appId), -1)
        $appHandle = $result.qReturn.qHandle
        
        Write-Host "Opened app: $appId (Handle: $appHandle)" -ForegroundColor Green
        return [QlikApp]::new($this, $appId, $appHandle)
    }

    # globals
    [object] GetDocList() {
        $result = $this.InvokeMethod("GetDocList", @(), -1)
        return $result.qDocList
    }

    [object] GetStreams() {
        try {
            $docList = $this.GetDocList()
            $streamMap = @{}
            
            foreach ($doc in $docList) {
                if ($doc.qMeta.stream.id) {
                    $streamId = $doc.qMeta.stream.id
                    if (-not $streamMap.ContainsKey($streamId)) {
                        $streamMap[$streamId] = @{
                            id = $streamId
                            name = $doc.qMeta.stream.name
                        }
                    }
                }
            }
            
            return $streamMap.Values
        } catch {
            Write-Warning "Failed to get streams: $_"
            return @()
        }
    }

    [object] GetAppsList() {
        return $this.GetAppsList($null)
    }

    [object] GetAppsList([string]$streamId) {
        try {
            $docList = $this.GetDocList()
            $apps = @()
            
            foreach ($doc in $docList) {
                $app = @{
                    id = $doc.qDocId
                    name = if ($doc.qDocName) { $doc.qDocName } else { $doc.qTitle }
                    title = $doc.qTitle
                    streamId = $doc.qMeta.stream.id
                    streamName = if ($doc.qMeta.stream.name) { $doc.qMeta.stream.name } else { "Personal" }
                    modified = $doc.qMeta.modifiedDate
                }
                
                if (-not $streamId -or $app.streamId -eq $streamId) {
                    $apps += $app
                }
            }
            
            return $apps
        } catch {
            Write-Warning "Failed to get apps list: $_"
            return @()
        }
    }
}
