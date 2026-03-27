$today = (Get-Date).Date
$previousMonday = $today.AddDays(1 - 7 -($today.DayOfWeek.value__) ).ToShortDateString() -replace "-", "."

$vbScriptPath = "C:\Users\<Username>\AppData\Roaming\SAP\SAP GUI\Scripts\tidsregistrering.vbs"
$vbCreationTime = (Get-ChildItem -Path $vbScriptPath -ErrorAction SilentlyContinue).CreationTime
#Test om script allerede er kørt i denne uge (regner med at køre det på lås op af PC)
if ($vbCreationTime) {
    $vbCreationMonday = ($vbCreationTime.Date).AddDays(1 - ($vbCreationTime.Date).DayOfWeek.value__).Date
    if (($today - $vbCreationMonday).Days -le 6) {
        Exit 0
    } 
}

$connectionString = @"
If Not IsObject(application) Then
   Set SapGuiAuto  = GetObject("SAPGUI")
   Set application = SapGuiAuto.GetScriptingEngine
End If
If Not IsObject(connection) Then
   Set connection = application.Children(0)
End If
If Not IsObject(session) Then
   Set session    = connection.Children(0)
End If
If IsObject(WScript) Then
   WScript.ConnectObject session,     "on"
   WScript.ConnectObject application, "on"
End If
"@
# $($sapuser), $($sapprw) and $($sapEmployeeID) should be set in a profile
$loginString = @"
session.findById("wnd[0]").maximize
session.findById("wnd[0]/usr/txtRSYST-MANDT").text = "100"
session.findById("wnd[0]/usr/txtRSYST-BNAME").text = "$($sapuser)"
session.findById("wnd[0]/usr/pwdRSYST-BCODE").text = "$($sapprw)"
session.findById("wnd[0]/usr/txtRSYST-LANGU").text = "DA"
session.findById("wnd[0]").sendVKey 0
"@

$openRegisterPageString = @"
session.findById("wnd[0]").maximize
session.findById("wnd[0]/usr/ctxtTCATST-VARIANT").text = "POLITI-3"
session.findById("wnd[0]/usr/ctxtCATSFIELDS-INPUTDATE").text = "$($previousMonday)"
session.findById("wnd[0]/usr/ctxtCATSFIELDS-PERNR").text = "$($sapEmployeeID)"
session.findById("wnd[0]/tbar[1]/btn[5]").press
"@

<#
-DAY1[6,4] = Mandag 63001
-DAY2[9,4] = Tirsdag 63001
osv...
#>

#Mangler check for registreret ferie
$registerHoursString = @"
`n
Dim ActivityText63001 As String
Dim ActivityText98001 As String
Dim RowIndex
'Random 20 rows som jeg tæller på
for RowCount 4 to 20 
    'Tjekker kolonne 1 da fridage og helligdage ikke har en aktivitet, men rettere en fravaersaktivitet
    ActivityText63001 = session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/ctxtCATS_ADDFI-FIELD4[1,RowIndex]").text
    ActivityText98001 = session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/ctxtCATS_ADDFI-FIELD4[1,RowIndex+1]").text
    If ActivityText63001 = "" and ActivityText98001 = "" Then
        RowIndex = RowCount
        Exit For
    End If
Next 
session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/ctxtCATS_ADDFI-FIELD4[3,RowIndex]").text = "63001"
session.findById("wnd[0]").sendVKey 0
session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/ctxtCATS_ADDFI-FIELD4[3,RowIndex+1]").text = "98001"
session.findById("wnd[0]").sendVKey 0
"@
#1 = Mandag til 5=Fredag
for ($i = 1; $i -le 5; $i++) {
    $columnOffset = 3 + 3 * $i
    $addString = @"
Dim field1Text$($i) As String
Dim field2Text$($i) As String
Dim restTid$($i) As String
restTid$($i) = session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/txtCATSD-DAY$($i)[$($columnOffset),3]").text
If restTid$($i) = "7,4" Then
    field1Text$($i) = session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/txtCATSD-DAY$($i)[$($columnOffset),RowIndex]").text
    If field1Text$($i) = "" Then
        session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/txtCATSD-DAY$($i)[$($columnOffset),RowIndex]").text = "6,9"
        session.findById("wnd[0]").sendVKey 0
    End If
    field2Text$($i) = session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/txtCATSD-DAY$($i)[$($columnOffset),RowIndex+1]").text
    If field2Text$($i) = "" Then
        session.findById("wnd[0]/usr/subCATS002:SAPLCATS:2200/tblSAPLCATSTC_CATSD/txtCATSD-DAY$($i)[$($columnOffset),RowIndex+1]").text = "0,5"
        session.findById("wnd[0]").sendVKey 0
    End If
End If
"@
$registerHoursString = @"
    $($registerHoursString)`n$($addString)`n
"@
}
#Tryk på 'Gem' efter
$registerHoursString = "$registerHoursString`nsession.findById(`"wnd[0]/tbar[0]/btn[11]`").press"


#Kombinerer scripts og ligger dem i en fil
$fullVBScript = @"
$connectionString`n
$loginString`n
$openRegisterPageString`n
$registerHoursString
"@



$fullVBScript | Out-File -FilePath $vbScriptPath


<#SAP GUI OPSTART#>
$SAPGUIPath = "C:\Program Files (x86)\SAP\FrontEnd\SAPgui\sapgui.exe"
$serverName = "ServerName"
$InstanceNr = "00"

#Starter SAP GUI
& $SAPGUIPath $serverName $InstanceNr

While ((Get-Process -Name saplogon -ErrorAction SilentlyContinue) -eq $null) {
    Start-Sleep 1
}
$SAPProcess = Get-Process -Name saplogon 

#Kalder script 
& c:\windows\system32\cscript.exe $vbScriptPath

$SAPProcess.Kill()