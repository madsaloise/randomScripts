# SIT Cloud Tests

Test scripts til Qlik Sense SaaS / Cloud miljøet. Verificerer at forskellige funktioner virker som forventet.

## Hovedscript

### TestConnect.ps1
Main test script der kører en suite af tests mod Qlik Sense Cloud QMC (Qlik Management Console).

**Hvad tester det:**
- Forbindelse til QMC API
- Import af diverse test moduler
- Verificerer forskellige aspekter af Qlik Sense Cloud setup

**Output:** Genererer HTML test log i `Output\` mappen med resultater.

### WhatToTest.txt
Dokumentation af hvad der skal testes og hvorfor.

## Modules Mappe

Test moduler der hver især tester en specifik del af Qlik Sense Cloud:

- **ADDirectories.psm1** - Active Directory integration
- **AssignedUsers.psm1** - User assignments og roller
- **ClientClass.ps1** - Client klasse til API kommunikation
- **OpenQVDesktopFiles.psm1** - QlikView Desktop filer
- **QDSTasks.psm1** - Qlik Data Services tasks
- **QMCModules.psm1** - QMC generelt
- **ServiceSettings.psm1** - Service indstillinger
- **ServiceStatus.psm1** - Service status checks
- **TaskInfo.psm1** - Task information

## Brug

Kør TestConnect.ps1 og tjek den genererede HTML log for at se test resultater:

```powershell
.\TestConnect.ps1 -QMSHost "your-qlik-host.com" -QMSPort 4799
```

## Tips

- Kør disse tests efter en opdatering af Qlik Sense Cloud miljøet
- Gem test logs til dokumentation af miljøets tilstand over tid
- Tilpas tests i modulerne hvis der er specifikke ting du vil verificere
