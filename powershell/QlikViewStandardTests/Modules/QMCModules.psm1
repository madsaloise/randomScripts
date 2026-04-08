# QlikView Management Service API helpers
function Get-SoapAction {
    param([string]$iface, [string]$operation)

    $baseNs = "http://ws.qliktech.com/QMS/12"

    # IQMS (v1) 
    if ($iface -eq "IQMS") {
        return "$baseNs/IQMS/$operation"
    }

    $ver = $iface -replace "IQMS", ""
    return "$baseNs/$ver/$iface/$operation"
}


function Get-XmlNamespace {
    param([string]$iface)

    $baseNs = "http://ws.qliktech.com/QMS/12"

    if ($iface -eq "IQMS") {
        return $baseNs
    }

    $ver = $iface -replace "IQMS", ""
    return "$baseNs/$ver/"
}

Export-ModuleMember -Function Get-SoapAction, Get-XmlNamespace


