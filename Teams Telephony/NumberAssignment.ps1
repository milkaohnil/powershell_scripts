<#
.Synopsis
  The script is designed to automatically assign Numbers in Microsoft Teams Telephony
.OUTPUTS
   The script applies specific Numberassignments from a CSV-File with the Attributes User,TestNumber & Number
.NOTES
   ===========================================================================
	 Created on:   	01.12.2023
	 Created by:   	Mika Kreienbühl
	 Filename:     	xxx-number-assignment-teams_telephony.ps1
	===========================================================================
.COMPONENT
   The script utilizes the Microsoft Teams Management module to interact with Microsoft Teams and AzureAD Module to interact with Entra ID.
.DISCLAIMER
   When I ccreated this script, only God and Me knew what I was doing. Now only God does.
#>

$customer = Read-Host "Gebe den Kundennamen ein"
$LogPath = "C:\temp\"+$customer
$TranscriptPath = $LogPath+"\Transcript.log"
$DocuPath = $LogPath+"\Documentation.txt"
Write-Host "Stelle sicher, dass alle Benutzer, welche eine Nummer zugewiesen haben müssen, eine gültige Microsoft Teams Telephony Lizenz haben und drücke Enter" -BackgroundColor DarkRed
pause
$step = Read-Host "Möchtest du Testnummern zuweisen (A), Testnummern entfernen (B) oder die definitiven Nummern zuweisen (C)?"
if ($step -ne "A")
    {
        if ($step -ne "B")
        {
            if ($step -ne "C")
            {
                Write-Host "Ungültige Eingabe, bitte führe das Skript erneut aus..." -BackgroundColor Red
                exit
            }
        }
    }
Write-Host "Bitte fülle das CSV-File vom GitHub-Repository aus, kopiere es an einen beliebigen Pfad auf das Notebook und drücke anschliessend Enter"
pause
$csvPath = Read-Host "Füge nachfolgend den Pfad zum CSV ein inkl. des Dateinamens.csv"
$users = Import-Csv "$csvPath"

#Connect to Microsoft Teams
Connect-MicrosoftTeams
Connect-AzureAD

#Create Log & Documentation
New-Item -ItemType Directory $LogPath
Start-Transcript -Path $TranscriptPath
New-Item $DocuPath
Get-AzureADTenantDetail >> $DocuPath
Get-CsOnlineSipDomain >> $DocuPath

#Assign Testnumber
if ($step -like "A")
    {
        Write-Host "Testnummern zuweisen..."
        foreach ($user in $users)
            {
                Set-CsPhoneNumberAssignment -Identity $user.User -PhoneNumber $userTestNumber -PhoneNumberType OperatorConnect
                Get-CsOnlineUser $user | ft UserPrincipalName,LineUri,FeatureTypes >> $DocuPath
            }
        Write-Host "Testnummern zugewiesen. Eine Übersicht der Benutzer sowie ein Powershell Transkript, findest du unter $LogPath." -BackgroundColor Gray -ForegroundColor Yellow
    }
#Deassign Testnumber
elseif ($step -like "B")
    {
        Write-Host "Testnummern entfernen..."
        "Testnummer:" >> $DocuPath
        foreach ($user in $users)
            {
                Get-CsOnlineUser $user | ft UserPrincipalName,LineUri,FeatureTypes >> $DocuPath
                Remove-CsPhoneNumberAssignment -Identity $user.User -PhoneNumber $user.Testnumber -PhoneNumberType OperatorConnect
            }
        Write-Host "Testnummern entfernt. Eine Übersicht der Benutzer sowie ein Powershell Transkript, findest du unter $LogPath." -BackgroundColor Gray -ForegroundColor Yellow
        "###Oben stehende Testnummern entfernt###" >> $DocuPath
    }
#Assign Number
elseif ($step -like "C")
    {
        Write-Host "Definitive Nummern zuweisen..."
        foreach ($user in $users)
            {
                Set-CsPhoneNumberAssignment -Identity $user.User -PhoneNumber $user.Number -PhoneNumberType OperatorConnect
                Get-CsOnlineUser $user | ft UserPrincipalName,LineUri,FeatureTypes >> $DocuPath
            }
            Write-Host "Definitive Nummern zugewiesen. Eine Übersicht der Benutzer sowie ein Powershell Transkript, findest du unter $LogPath." -BackgroundColor Gray -ForegroundColor Yellow
    }
else
    {
        Write-Host "ungültige Eingabe, Skript wird beendet..." -BackgroundColor Red
    }
    Stop-Transcript
    Write-Host "Kopiere die erstellten Dokumentationen auf das Kundenlaufwerk." -BackgroundColor Green -ForegroundColor Black
