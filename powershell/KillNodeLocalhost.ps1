Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue | 
  Select-Object -ExpandProperty OwningProcess -Unique | 
  ForEach-Object { 
    $proc = Get-Process -Id $_ -ErrorAction SilentlyContinue
    if ($proc.ProcessName -eq 'node') {
      Stop-Process -Id $_ -Force
      Write-Host "Killed node.exe process ID $_"
    } else {
      Write-Host "Port 3000 is used by: $($proc.ProcessName) - not killing"
    }
  }