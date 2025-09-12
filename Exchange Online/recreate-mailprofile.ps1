<# 
.SYNOPSIS
Liest das Standard-Outlookprofil aus, sichert es, löscht es und erstellt es neu (Autodiscover).
Unterstützt Office/Outlook 2013–M365 (Registry 15.0/16.0).

.PARAMETER NewProfileName
Name des neu zu erstellenden Profils (Default: bisheriges Default-Profil, sonst "Outlook").

.PARAMETER Upn
UPN/Primäre E-Mail des Benutzers für Autodiscover. 
Wenn leer: versucht $env:USERNAME@$env:USERDNSDOMAIN, sonst wird interaktiv abgefragt.

.NOTES
    ===========================================================================
	 Created on:   	12.09.2025
	 Created by:   	Mika Kreienbühl
	 Filename:     	recreate-mailprofile.ps1
     Version:      	1.0.0
    ===========================================================================
    Dieses Skript wird ohne Gewährleistung jeglicher Art bereitgestellt. Der Autor übernimmt keine Haftung für Schäden,
    die durch die Nutzung dieses Skripts entstehen könnten. Vor der Ausführung sollten Sie den Code sorgfältig prüfen und sicherstellen,
    dass Sie über aktuelle Backups verfügen.
    ===========================================================================
    When I created this script, only God and Me knew what I was doing. Now only God does.
    The script was created with sweat, coffee and lots of love.
    ===========================================================================
#>

[CmdletBinding()]
param(
    [string]$NewProfileName,
    [string]$Upn
)

function Get-OutlookVersionKey {
    # Priorität: 16.0 (O365/2016+) -> 15.0 (2013)
    $roots = @(
        'HKCU:\Software\Microsoft\Office\16.0\Outlook',
        'HKCU:\Software\Microsoft\Office\15.0\Outlook'
    )
    foreach ($r in $roots) {
        if (Test-Path $r) { return $r }
    }
    return $null
}

function Get-OutlookExePath {
    # Häufige Orte Click-to-Run
    $c2r = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\OUTLOOK.EXE'
    if (Test-Path $c2r) {
        (Get-ItemProperty $c2r).'(Default)'
    } else {
        # Fallback: Standardpfade
        $candidates = @(
            "$env:ProgramFiles\Microsoft Office\root\Office16\OUTLOOK.EXE",
            "$env:ProgramFiles(x86)\Microsoft Office\root\Office16\OUTLOOK.EXE",
            "$env:ProgramFiles\Microsoft Office\Office16\OUTLOOK.EXE",
            "$env:ProgramFiles(x86)\Microsoft Office\Office16\OUTLOOK.EXE",
            "$env:LOCALAPPDATA\Microsoft\WindowsApps\OUTLOOK.EXE"
        )
        $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    }
}

try {
    # 0) Sicherstellen, dass klassisches Outlook vorhanden ist
    $outlookKey = Get-OutlookVersionKey
    if (-not $outlookKey) {
        throw "Kein klassisches Outlook-Profil gefunden. Vermutlich wird das neue Outlook (Monarch) verwendet - dieses Skript ist dafür nicht geeignet."
    }

    # 1) Outlook schließen
    $running = Get-Process OUTLOOK -ErrorAction SilentlyContinue
    if ($running) {
        Write-Host "Outlook wird beendet…" -ForegroundColor Yellow
        $running | Stop-Process -Force
        Start-Sleep -Seconds 2
    }

    # 2) Profile & DefaultProfile ermitteln
    $profilesKey = Join-Path $outlookKey 'Profiles'
    if (-not (Test-Path $profilesKey)) {
        throw "Kein Profiles-Zweig gefunden unter $profilesKey."
    }

    $defaultProfileValueKey = Join-Path (Join-Path $outlookKey 'Options\General') '.'
    $defaultProfile = $null
    if (Test-Path (Join-Path $outlookKey 'Options\General')) {
        try {
            $defaultProfile = (Get-ItemProperty (Join-Path $outlookKey 'Options\General')).DefaultProfile
        } catch {
            Write-Host "DefaultProfile-Eintrag nicht gefunden." -ForegroundColor Yellow
        }
    }

    # Falls DefaultProfile leer ist, nimm das erste Profil
    if (-not $defaultProfile) {
        $existingProfiles = (Get-ChildItem $profilesKey -ErrorAction Stop | Where-Object { $_.PSChildName -ne 'Properties' }).PSChildName
        if ($existingProfiles.Count -eq 0) {
            throw "Es existiert kein Profil unter $profilesKey - nichts zu löschen."
        }
        $defaultProfile = $existingProfiles | Select-Object -First 1
    }

    Write-Host "Gefundenes Default-Profil: $defaultProfile" -ForegroundColor Cyan

    # Namen für das neue Profil
    if (-not $NewProfileName -or [string]::IsNullOrWhiteSpace($NewProfileName)) {
        $NewProfileName = $defaultProfile
    }

    # 3) Backup exportieren
    $backupDir = Join-Path $env:TEMP "OutlookProfileBackup"
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    $profileRegPath = "HKCU\Software\Microsoft\Office\{0}\Outlook\Profiles\{1}" -f ($outlookKey -replace '.*Office\\([0-9\.]+)\\Outlook','$1'), $defaultProfile
    $backupFile = Join-Path $backupDir ("{0}_backup_{1:yyyyMMdd_HHmmss}.reg" -f $defaultProfile,(Get-Date))
    Write-Host "Exportiere Profil-Backup nach: $backupFile"
    & reg.exe export $profileRegPath $backupFile /y | Out-Null

    # 4) Profil löschen
    $profileKeyToRemove = Join-Path $profilesKey $defaultProfile
    if (Test-Path $profileKeyToRemove) {
        Write-Host "Lösche altes Profil '$defaultProfile'…" -ForegroundColor Yellow
        Remove-Item -Path $profileKeyToRemove -Recurse -Force
    }

    # 5) DefaultProfile auf neuen Namen setzen
    $optionsGeneralKey = Join-Path $outlookKey 'Options\General'
    if (-not (Test-Path $optionsGeneralKey)) {
        New-Item -Path $optionsGeneralKey -Force | Out-Null
    }
    New-ItemProperty -Path $optionsGeneralKey -Name 'DefaultProfile' -Value $NewProfileName -PropertyType String -Force | Out-Null

    # 6) UPN ermitteln (für Autodiscover)
    if (-not $Upn -or [string]::IsNullOrWhiteSpace($Upn)) {
        if ($env:USERDNSDOMAIN) {
            $Upn = "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
        }
    }
    while (-not $Upn -or -not ($Upn -match '^[^@]+@[^@]+\.[^@]+$')) {
        $Upn = Read-Host "Bitte primäre E-Mail/UPN für Autodiscover eingeben (z.B. max.muster@firma.ch)"
    }

    # 7) PRF-Datei generieren
    $workDir = Join-Path $env:TEMP "OutlookProfileReset"
    New-Item -Path $workDir -ItemType Directory -Force | Out-Null
    $prfPath = Join-Path $workDir "create_profile.prf"

    $prf = @"
; Automatically generated PRF for Outlook profile creation
; Docs: https://support.microsoft.com/en-us/topic/how-to-create-prf-files-to-configure-outlook-profiles-b4c59f3a-7e9c-0f38-8f4b-0c6ee45b8f93

[General]
Custom=1
ProfileName=$NewProfileName
DefaultProfile=Yes
OverwriteProfile=Yes
ModifyDefaultProfileIfPresent=False

[Service List]
; Only rely on AutoDiscover (no explicit EX service block)

[Microsoft Exchange Server]
; Left intentionally blank; Autodiscover handles it.

[Internet Account List]

[Unicode]
DoUnicode=True

[AutoDiscover]
AutoDiscoverConnectionMethod=EXCH
AutoDiscoverUserName=$Upn
AutoDiscoverEmailAddress=$Upn
AutoDiscoverPrompt=False
AutoDiscoverSelection=Auto
"@

    $prf | Set-Content -Path $prfPath -Encoding ASCII

    # 8) Outlook /importprf aufrufen
    $outlook = Get-OutlookExePath
    if (-not $outlook -or -not (Test-Path $outlook)) {
        throw "OUTLOOK.EXE wurde nicht gefunden. Bitte Office-Installation prüfen."
    }

    Write-Host "Erstelle neues Profil '$NewProfileName' via PRF/Autodiscover…" -ForegroundColor Green
    & "$outlook" "/importprf" "$prfPath"
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Outlook /importprf meldete ExitCode $LASTEXITCODE. Das Profil wird beim nächsten Start ggf. interaktiv erstellt."
    }

    # 9) Optional: Outlook starten, um Autodiscover durchlaufen zu lassen
    Write-Host "Starte Outlook, damit Autodiscover das Profil befüllt…" -ForegroundColor Green
    Start-Process -FilePath "$outlook" -ArgumentList "/profile `"$NewProfileName`""

    # 10) Name des alten Profils protokollieren
    $nameLog = Join-Path $workDir "old_profile_name.txt"
    $defaultProfile | Out-File -FilePath $nameLog -Encoding UTF8

    Write-Host "`nFertig. Backup: $backupFile `nArbeitsverzeichnis: $workDir" -ForegroundColor Cyan
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
