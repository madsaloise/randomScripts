$script:LogFile = $null
$script:UseHtmlLog = $false

function ConvertTo-HtmlEncoded {
    param([string]$Text)
    return $Text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;' -replace '"', '&quot;' -replace "'", '&#39;'
}

# ANSI color codes for text output
$script:AnsiColors = @{
    'Black'       = "`e[30m"
    'DarkBlue'    = "`e[34m"
    'DarkGreen'   = "`e[32m"
    'DarkCyan'    = "`e[36m"
    'DarkRed'     = "`e[31m"
    'DarkMagenta' = "`e[35m"
    'DarkYellow'  = "`e[33m"
    'Gray'        = "`e[37m"
    'DarkGray'    = "`e[90m"
    'Blue'        = "`e[94m"
    'Green'       = "`e[92m"
    'Cyan'        = "`e[96m"
    'Red'         = "`e[91m"
    'Magenta'     = "`e[95m"
    'Yellow'      = "`e[93m"
    'White'       = "`e[97m"
    'Reset'       = "`e[0m"
}

# HTML color codes
$script:HtmlColors = @{
    'Black'       = '#000000'
    'DarkBlue'    = '#000080'
    'DarkGreen'   = '#008000'
    'DarkCyan'    = '#008080'
    'DarkRed'     = '#800000'
    'DarkMagenta' = '#800080'
    'DarkYellow'  = '#808000'
    'Gray'        = '#C0C0C0'
    'DarkGray'    = '#808080'
    'Blue'        = '#0000FF'
    'Green'       = '#00FF00'
    'Cyan'        = '#00FFFF'
    'Red'         = '#FF0000'
    'Magenta'     = '#FF00FF'
    'Yellow'      = '#FFFF00'
    'White'       = '#FFFFFF'
}

function Start-EnhancedLog {
    <#
    .SYNOPSIS
        Starts a color-preserving log file.
    
    .PARAMETER LogPath
        Path to the log file. Use .html extension for HTML format, .txt/.log for ANSI format.
    
    .EXAMPLE
        Start-EnhancedLog -LogPath "C:\logs\test.html"
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )
    
    $script:LogFile = $LogPath
    $script:UseHtmlLog = $LogPath -match '\.html?$'
    
    if ($script:UseHtmlLog) {
        $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>PowerShell Log - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</title>
    <style>
        body { background-color: #012456; font-family: 'Consolas', 'Courier New', monospace; font-size: 14px; padding: 20px; }
        pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }
    </style>
</head>
<body>
<pre>
"@
        Set-Content -Path $LogPath -Value $htmlHeader -Encoding UTF8
    }
    else {
        Set-Content -Path $LogPath -Value "" -Encoding UTF8
    }
    
    Write-Host "Log started: $LogPath" -ForegroundColor Green
}

function Stop-EnhancedLog {
    <#
    .SYNOPSIS
        Stops logging and closes the log file.
    #>
    
    if ($script:UseHtmlLog -and $script:LogFile) {
        $htmlFooter = @"
</pre>
</body>
</html>
"@
        Add-Content -Path $script:LogFile -Value $htmlFooter -Encoding UTF8
    }
    
    if ($script:LogFile) {
        Write-Host "Log saved: $script:LogFile" -ForegroundColor Green
        $script:LogFile = $null
    }
}

function Write-EnhancedLog {
    <#
    .SYNOPSIS
        Writes a message to console with color and to the log file preserving colors.
    
    .PARAMETER Message
        The message to write
    
    .PARAMETER ForegroundColor
        Console foreground color
    
    .PARAMETER NoNewline
        Don't add a newline after the message
    
    .EXAMPLE
        Write-EnhancedLog "Success!" -ForegroundColor Green
    #>
    param(
        [Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        [string]$Message = "",
        
        [Parameter(Mandatory=$false)]
        [System.ConsoleColor]$ForegroundColor = 'White',
        
        [Parameter(Mandatory=$false)]
        [switch]$NoNewline
    )
    
    # Write to console
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $ForegroundColor -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
    
    # Write to log file if active
    if ($script:LogFile) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        
        if ($script:UseHtmlLog) {
            # HTML format with colors
            $colorHex = $script:HtmlColors[$ForegroundColor.ToString()]
            $escapedMessage = ConvertTo-HtmlEncoded -Text $Message
            $logLine = "<span style='color: $colorHex;'>$escapedMessage</span>"
            if (-not $NoNewline) {
                $logLine += "`n"
            }
        }
        else {
            # ANSI format with colors
            $ansiColor = $script:AnsiColors[$ForegroundColor.ToString()]
            $ansiReset = $script:AnsiColors['Reset']
            $logLine = "$ansiColor$Message$ansiReset"
            if (-not $NoNewline) {
                $logLine += "`n"
            }
        }
        
        Add-Content -Path $script:LogFile -Value $logLine -NoNewline -Encoding UTF8
    }
}

Export-ModuleMember -Function Start-EnhancedLog, Stop-EnhancedLog, Write-EnhancedLog
