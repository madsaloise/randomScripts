#Install
#Install-Module -Name QlikView-CLI

#Import
#Import-module QlikView-CLI

#Hvis rettighedsproblemer: Tilføjer en bruger ved at:
#System -> Setup -> Distribution Services QDS@ServerName-> General -> Path -> Tilføj Document Administrator -> Apply
#Skal også tilføjes QV management API gennem lokal brugerkontrol.



[cmdletbinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage = "Obligatorisk. Navn på QlikView-dokument, hvis task skal igangsættes. Eksempel: Tilhold.qvw")][string]$documentName,
    [Parameter(Mandatory=$false, HelpMessage = "Optionel. Den QV-Server, som der skal forbindes til. Eksempel: servername.net")][string]$Hostname
    )



#opretter forbindelse til QMC
Try {
    $Connection = Connect-QlikView -Hostname $Hostname -Version IQMS5 
}
Catch {
    Write-Host "Der opstod en fejl med at forbindelse til QMC:"
    Write-Host $_
    Exit 1
}

#Finder distribution service ID og opretter en klient
$qdsID = $Connection.QlikViewDistributionService.ID
$client = $Connection.client

Try {
    $SourceDocs = $client.GetSourceDocuments($qdsID) | Where-Object {$_.Name -eq $documentName -and $_.TaskCount -ge 1 }
    if ($SourceDocs) {
        foreach ($doc in $SourceDocs) {   
            $tasks = $client.GetTasksForDocument($SourceDocs.ID) 
            Foreach ($task in $tasks) {
                $startTime = $client.GetTaskStatus($task.ID, "All").Extended.StartTime
                If ($task.Enabled -eq $false -or $startTime -eq "Not scheduled") {
                    $confirmation = Read-Host "Tasken er er disabled eller ikke scheduleret. Vil du stadig køre tasken? [y/n]" 
                    if ($confirmation -ne 'y') {
                        Write-Host "Springer '$($task.Name)' for dokumentet'$($doc.Name)' over..."
                        Continue
                    } 
                }
                Write-Host "Kører task: '$($task.Name)' for dokumentet'$($doc.Name)' på stien $($doc.RelativePath)..."
                $client.RunTask($task.ID)
                Start-Sleep 5
                Do {
                    Start-Sleep 5
                    $taskStatus = $client.GetTaskStatus($task.ID, "All")               
                } until ($taskStatus.General.Status -eq "Waiting" -or $taskStatus.General.Status -eq "Failed")
                
                if ($taskStatus.General.Status -eq "Waiting") {
                    Write-Host "Tasken '$($task.Name)' er kørt uden problemer."
                } else {
                    Write-Host "Tasken '$($task.Name)' har fejlet."
                    Write-Host "Lukker script.."
                    Exit 1
                } 
            } 
        }  
    } else {Write-Host "Ingen tasks fundet på dette dokument."}
} catch {
    Write-Host "Der opstod en fejl i forbindelse med at køre tasken:"
    write-Host $_
    Exit 1
}
















