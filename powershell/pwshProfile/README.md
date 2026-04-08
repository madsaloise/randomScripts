# PowerShell Profile Modules

Genbrugelige PowerShell moduler der kan importeres i dine scripts eller profile.

## Moduler

### EnhancedLogger.psm1
Avanceret logging modul med farvet console output og HTML log generation.

**Features:**
- Farvet output til console med ANSI codes
- Kan generere pæne HTML logs
- Forskellige log niveauer (info, warning, error, success)
- Brugt af mange andre scripts i dette repo

**Brug:**
```powershell
Import-Module .\pwshProfile\EnhancedLogger.psm1
Start-EnhancedLog -LogPath "C:\logs\mylog.html"
Write-EnhancedLog "Dette er en log besked" -ForegroundColor Green
Stop-EnhancedLog
```

### Send-OutlookMail.psm1
Wrapper til at sende emails via Outlook COM objektet.

**Brug:**
```powershell
Import-Module .\pwshProfile\Send-OutlookMail.psm1
Send-OutlookMail -To "email@domain.dk" -Subject "Test" -Body "Besked" -Attachments @("C:\fil.txt")
```

## Installation i Profile

Hvis du vil have disse moduler tilgængelige i alle dine PowerShell sessions, kan du importere dem i din PowerShell profile:

```powershell
# Åbn din profile
notepad $PROFILE

# Tilføj disse linjer
Import-Module "E:\MchWork-1\pwshProfile\EnhancedLogger.psm1"
Import-Module "E:\MchWork-1\pwshProfile\Send-OutlookMail.psm1"
```

## Tips

Disse moduler bruges også af andre scripts i dette repo - især MonthlyTasks bruger EnhancedLogger flittigt!
