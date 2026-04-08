Function Import-SQLToQVTranslations {
    $Translations = @(
    #Grundtabeller
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.JOURPERS';  QVName = '$(Jourpers_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.AFGREG';  QVName = '$(Afgreg_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.JOURNAL';  QVName = '$(Journal_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.Kreds';  QVName = '$(Kreds_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.SAGSPLAC';  QVName = '$(Sagsplac_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.AKTERING';  QVName = '$(Aktering_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.ANHOLDTE';  QVName = '$(Anholdte_Tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.AFDELING';  QVName = '$(Afdeling_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).REFERENCE.AFGTYPE';  QVName = '$(Afgtype_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).REFERENCE.GERNINGSKODER';  QVName = '$(Gerningskode_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).REFERENCE.KALENDER';  QVName = '$(Kalender_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).REFERENCE.SAGSTATUS';  QVName = '$(Sagsstatus_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).REFERENCE.KONVGLNYPOLITIKREDS';  QVName = '$(NyGammelKreds_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.EFTERFORSKNING_MODUS';  QVName = '$(Soegenoegle_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.RPC_PERSON';  QVName = '$(RPC_PERSON_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLSAS.RPC_BRUGER';  QVName = '$(RPC_BRUGER_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).POLPAI.DSOWRX';  QVName = '$(PolPai_DSOWRX_tabel)'}
    [PSCustomObject]@{SQLName = '$(Exploration).KR.SIGTELSER';  QVName = '$(KR_Sigtelse_tabel)'}
    )
    Return $Translations
}