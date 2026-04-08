function Get-ServiceSettings {
    <#
    .SYNOPSIS
        Gets QlikView service settings
    
    .PARAMETER ApiClient
        The QMS API client instance
    
    .PARAMETER serviceType
        The service type to retrieve settings for
    
    .OUTPUTS
        XML result containing service settings
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]$ApiClient,
        
        [Parameter(Mandatory=$true)]
        [string]$serviceType,
        
        [Parameter(Mandatory=$false)]
        [switch]$ShowFullXml
    )
    
    if ($serviceType -ne "QVPR") {
        $servicesResult = $ApiClient.InvokeMethod("GetServices", @{ serviceTypes = $serviceType })
        $services = @($servicesResult.ServiceInfo)
        if (-not $services -or $services.Count -eq 0) {
            Write-EnhancedLog "No service found of type: $serviceType" -ForegroundColor Yellow
            return $null
        }
    }

    switch ($serviceType) {
        "QlikViewDistributionService" {
            $method = "GetQDSSettings" 
            $param = [ordered]@{ qdsID = $services[0].ID; scope = "All" }
            
        } "QVPR" {
            $method = "GetQVPRAPISettings"
            $param = @{}
        } "QlikViewDirectoryServiceConnector" {
            $method = "GetDSCAPISettings"
            $param = @{ dscID = $services[0].ID }
        } "QlikViewServer" {
            $method = "GetQVSSettings"
            $param = @{ qvsID = $services[0].ID; scope = "All" }
        } "QlikViewWebServer" {
            $method = "GetQVWSSetting"
            $param = @{ qvwsID = $services[0].ID }
        } 

        default {
            Write-EnhancedLog "Unsupported service type: $serviceType" -ForegroundColor Yellow
            return $null
        }
    }

    try {
        $settingsResult = $ApiClient.InvokeMethod($method, $param, $true)
        
        Write-EnhancedLog "`nRetrieving settings for $($serviceType)" -ForegroundColor Cyan

        if ($settingsResult -is [xml]) {
            $responseNode = $settingsResult.Envelope.Body.FirstChild
            $resultNode = $responseNode.FirstChild
            
            # Show full XML
            if ($ShowFullXml) {
                Write-EnhancedLog "`n=== FULL XML ENVELOPE ===" -ForegroundColor Magenta
                Write-EnhancedLog $settingsResult.OuterXml -ForegroundColor Gray
                Write-EnhancedLog "=== END FULL XML ===`n" -ForegroundColor Magenta
                
                Write-EnhancedLog "=== RESULT NODE ONLY ===" -ForegroundColor Magenta
                Write-EnhancedLog $resultNode.OuterXml -ForegroundColor Gray
                Write-EnhancedLog "=== END RESULT NODE ===`n" -ForegroundColor Magenta
            }
            
            if ($resultNode) {
                $settingsNode = $resultNode
                if ($resultNode.ChildNodes.Count -eq 1 -and $resultNode.FirstChild.NodeType -eq "Element") {
                    $settingsNode = $resultNode.FirstChild
                }
                
                if ($settingsNode.HasChildNodes) {                
                    foreach ($child in $settingsNode.ChildNodes) {
                        if ($child.NodeType -ne "Element") { continue }
                        
                        if ($child.HasChildNodes -and $child.FirstChild.NodeType -eq "Element") {
                            foreach ($subChild in $child.ChildNodes) {
                                $indent = "  "
                                if ($subChild.NodeType -eq "Element") {
                                }
                            }
                        }
                    }
                }
                
                $settingsObject = [PSCustomObject]@{}
                
                function Add-PropertyRecursive {
                    param($node, $prefix = "")
                    
                    foreach ($child in $node.ChildNodes) {
                        if ($child.NodeType -ne "Element") { continue }
                        
                        $propertyName = if ($prefix) { "$prefix`_$($child.LocalName)" } else { $child.LocalName }
                        $hasChildElements = $child.HasChildNodes -and $child.FirstChild.NodeType -eq "Element"
                        
                        if ($hasChildElements) {
                            Add-PropertyRecursive -node $child -prefix $propertyName
                        }
                        else {
                            $settingsObject | Add-Member -MemberType NoteProperty -Name $propertyName -Value $child.InnerText -ErrorAction SilentlyContinue
                        }
                    }
                }
                
                Add-PropertyRecursive -node $settingsNode
                
                return $settingsObject
            }
            else {
                Write-EnhancedLog "  No result node found in response" -ForegroundColor Yellow
                return $settingsResult
            }
        }
        else {
            Write-EnhancedLog "  Response is not XML, returning as-is" -ForegroundColor Yellow
            return $settingsResult
        }
    }
    catch {
        Write-EnhancedLog "Failed to retrieve settings for $($serviceType): $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function Get-ServiceSettings