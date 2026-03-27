
function Send-OutlookMail {
    param(
        [Parameter(Mandatory)][string[]]$To,
        [Parameter(Mandatory)][string]$Subject,
        [Parameter(Mandatory)][string]$Body,
        [string]$Attachments = $null,
        [switch]$IsHtml
    )

    $outlook = New-Object -ComObject Outlook.Application
    $mail    = $outlook.CreateItem(0)

    $mail.To      = ($To -join ";")
    $mail.Subject = $Subject

    if ($IsHtml) { $mail.HTMLBody = $Body } else { $mail.Body = $Body }

    if ($Attachments) {
        $mail.Attachments.Add($Attachments) | Out-Null
    }

    $mail.Send()

    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail)    | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null

    Write-Host "[Mail] Sent '$Subject' → $($To -join ', ')" -ForegroundColor Cyan
}

Export-ModuleMember -Function Send-OutlookMail