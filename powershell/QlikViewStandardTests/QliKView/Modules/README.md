# SIT Cloud Tests - Modules

Test moduler der hver især verificerer en specifik komponent eller funktionalitet i Qlik Sense Cloud.

## Test Moduler

### ClientClass.ps1
Definerer en client klasse til at kommunikere med Qlik Sense QMC API. Bruges af alle de andre test moduler til at lave API kald.

### ADDirectories.psm1
Tester integration med Active Directory - verificerer at AD mapper og konfiguration er korrekt.

### AssignedUsers.psm1
Tjekker user assignments - hvem har adgang til hvad, og om roller er tildelt korrekt.

### OpenQVDesktopFiles.psm1
Verificerer at QlikView Desktop filer kan åbnes og er tilgængelige.

### QDSTasks.psm1  
Tester Qlik Data Services tasks - at de er konfigureret og kan køre.

### QMCModules.psm1
Generelle QMC (Qlik Management Console) tests og hjælpefunktioner.

### ServiceSettings.psm1
Verificerer at service indstillinger er korrekte - typisk efter en opdatering eller migration.

### ServiceStatus.psm1
Status checks på alle Qlik services - er de i gang, responderer de, osv.

### TaskInfo.psm1
Henter og verificerer task information - reload tasks, status, trigger schedules osv.

## Udvikling

Når du tilføjer nye tests:

1. Opret et nyt modul her i Modules mappen
2. Importer ClientClass.ps1 for at få adgang til API client
3. Brug samme naming convention (`Test-XYZ` funktioner)
4. Tilføj import og kald i hovedscriptet `TestConnect.ps1`
5. Brug EnhancedLogger til at logge resultater

## Tips

- Hvert modul kan også køres individuelt til debugging
- Brug `Write-EnhancedLog` til at logge test resultater med farver
- Return værdier fra test funktioner bruges til at afgøre om tests bestod
