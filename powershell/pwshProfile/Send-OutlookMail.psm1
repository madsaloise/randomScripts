
function Send-OutlookMail {
    param(
        [Parameter(Mandatory)]
        [string[]]$To,
        [Parameter(Mandatory)]
        [string]$Subject,
        [Parameter(Mandatory)]
        [string]$Body,
        [string[]]$Cc,
        [string[]]$Attachments,
        [switch]$IsHtml
    )

    $outlook = New-Object -ComObject Outlook.Application
    $mail    = $outlook.CreateItem(0)

    $mail.To = ($To -join ";")
    if ($Cc) {
        $mail.CC = ($Cc -join ";")
    }
    $mail.Subject = $Subject
    if ($IsHtml) {
        $mail.HTMLBody = $Body
    } else {
        $mail.Body = $Body
    }
    if ($Attachments) {
        foreach ($file in $Attachments) {
            $mail.Attachments.Add($file) | Out-Null
        }
    }

    $mail.Send()

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail)    | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null

    $ccText = if ($Cc) { " | CC: $($Cc -join ', ')" } else { "" }
    Write-Host "[Mail] Sent '$Subject' → $($To -join ', ')$ccText" -ForegroundColor Cyan
}
Export-ModuleMember -Function Send-OutlookMail