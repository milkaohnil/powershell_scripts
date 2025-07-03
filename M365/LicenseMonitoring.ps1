# Requires 1 App-Registration with certificate authentication and the following permissions
# - Microsoft Graph: Application.Read.All, Directory.Read.All, User.Read.All, Mail.Send

param (
    [switch]$SaveHtml,
    [switch]$SendMail,
    [switch]$SendTeams,
    [string]$OutputPath = ".\M365Lizenzreport.html",
    [string]$MailTo = "YourRecipientEmailHere", # E-Mail-Adresse des Empfängers, muss im Tenant existieren
    [string]$MailFrom = "YourSenderEmailHere", # E-Mail-Adresse des Absenders, muss im Tenant existieren
    [string]$ClientId = "YourClientIdHere",
    [string]$TenantId = "YourTenantIdHere",
    [string]$CertificateThumbprint = "YourCertificateThumbprintHere",
    [string]$teamsWebhook = "YourTeamsWebhookUrlHere"
)

# Funktion: Konsolenpuffer stabilisieren
function Set-ConsoleBuffer {
    try {
        $ui = $Host.UI.RawUI
        $newSize = $ui.BufferSize
        $newSize.Height = 3000
        $ui.BufferSize = $newSize
    } catch {
        Write-Warning "Konnte Konsolenpuffer nicht anpassen: $_"
    }
}

# Funktion: Graph-Login sicher durchführen
function Connect-MgGraphSafe {
    try {
        if (-not (Get-MgContext)) {
            Write-Host "Authentifiziere mit Zertifikat..." -ForegroundColor Cyan
            Connect-MgGraph -ClientId $ClientId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint -NoWelcome
        }
    } catch {
        Write-Warning "Fehler beim Verbinden mit Graph: $_"
    }
}

# Funktion: Lizenzdaten laden
function Get-LicenseData {
    Get-MgSubscribedSku | Where-Object { $_.PrepaidUnits.Enabled -gt 0 }
}

function Get-TenantInfo {
    try {
        return (Get-MgOrganization).DisplayName
    } catch {
        Write-Warning "Konnte Tenant-Informationen nicht abrufen: $_"
        return "Unbekannt"
    }
}

# Funktion: HTML-Bericht erzeugen
function Generate-LicenseHtml($skus, $TenantName) {
    $rows = ""
    foreach ($sku in $skus) {
        $label = $sku.SkuPartNumber
        $enabled = $sku.PrepaidUnits.Enabled
        $used = $sku.ConsumedUnits
        $free = $enabled - $used
        $freePercent = if ($enabled -gt 0) { [math]::Round(($free / $enabled) * 100, 1) } else { 0 }

        $barColor = if ($freePercent -lt 1) { "#c62828" }
                    elseif ($freePercent -lt 15) { "#e65100" }
                    elseif ($freePercent -lt 20) { "#f57c00" }
                    elseif ($freePercent -lt 30) { "#ff9800" }
                    elseif ($freePercent -lt 50) { "#ffca28" }
                    elseif ($freePercent -lt 70) { "#107c10" }
                    elseif ($freePercent -lt 90) { "#78c679" }
                    else { "#28a745" }

if ($freePercent -eq 0) {
    # Vollrot bei 0%
    $rows += @"
<tr>
  <td>$label</td>
  <td>$enabled</td>
  <td>$used</td>
  <td>$free</td>
  <td>
    <div style='background:$barColor; width:100%; color:white; text-align:center; border-radius:4px; padding:2px 0;'>
      0&#37;
    </div>
  </td>
</tr>
"@
} else {
    # Balkenanzeige bei > 0%
    $rows += @"
<tr>
  <td>$label</td>
  <td>$enabled</td>
  <td>$used</td>
  <td>$free</td>
  <td>
    <div style='background:#e1e1e1; width:100%; border-radius:4px; text-align:center;'>
      <div style='width:$($freePercent)%; background:$barColor; color:white; text-align:center; border-radius:4px; padding:2px 0;'>
        $($freePercent)&#37;
      </div>
    </div>
  </td>
</tr>
"@
}

    }

    $dateNow = Get-Date -Format 'dd.MM.yyyy HH:mm'

    $html = @"
<html>
<head>
  <meta charset='UTF-8'>
  <style>
    body { font-family: "Segoe UI", sans-serif; padding: 20px; background-color: #f9f9f9; color: #333;}
    h2 { color: #0078d4; }
    table { width: 100%; border-collapse: collapse; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    th td { padding: 12px; border-bottom: 1px solid #ddd; text-align: left; }
    th { background-color: #0078d4; color: white; }
  </style>
</head>
<body>
  <h2>Microsoft 365 Lizenzreport - $TenantName</h2>
  <p>Stand: $dateNow</p>

  <table>
    <tr>
      <th>Lizenz</th>
      <th>Gekauft</th>
      <th>Verwendet</th>
      <th>Frei</th>
      <th>Frei in %</th>
    </tr>
    $rows
  </table>
</body>
</html>
"@

    return $html
}

function Get-AccessTokenWithCertificate {
    param (
        [string]$TenantId,
        [string]$ClientId,
        [string]$CertThumbprint
    )

    Add-Type -AssemblyName System.IdentityModel

    $cert = Get-ChildItem -Path Cert:\CurrentUser\My\$CertThumbprint
    if (-not $cert) {
        throw "Zertifikat mit Thumbprint '$CertThumbprint' nicht gefunden."
    }

    $now = [DateTime]::UtcNow
    $jwtHeader = @{
        alg = "RS256"
        typ = "JWT"
        x5t = [System.Convert]::ToBase64String($cert.GetCertHash())
    }

    $jwtPayload = @{
        aud = "https://login.microsoftonline.com/$TenantId/v2.0"
        iss = $ClientId
        sub = $ClientId
        jti = [Guid]::NewGuid().ToString()
        nbf = [int]($now - [datetime]'1970-01-01').TotalSeconds
        exp = [int]($now.AddMinutes(10) - [datetime]'1970-01-01').TotalSeconds
    }

    $jwtHeaderJson = ($jwtHeader | ConvertTo-Json -Compress)
    $jwtPayloadJson = ($jwtPayload | ConvertTo-Json -Compress)

    $enc = [System.Text.Encoding]::UTF8
    $toBase64Url = {
        param ($bytes)
        [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    }

    $headerBase64 = &$toBase64Url($enc.GetBytes($jwtHeaderJson))
    $payloadBase64 = &$toBase64Url($enc.GetBytes($jwtPayloadJson))
    $tokenToSign = "$headerBase64.$payloadBase64"

    $rsa = [System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($cert)
    if (-not $rsa) {
        throw "Privater Schlüssel konnte nicht aus dem Zertifikat extrahiert werden."
    }

    $signature = $rsa.SignData(
        $enc.GetBytes($tokenToSign),
        [Security.Cryptography.HashAlgorithmName]::SHA256,
        [Security.Cryptography.RSASignaturePadding]::Pkcs1
    )

    $signatureBase64 = &$toBase64Url($signature)

    $clientAssertion = "$tokenToSign.$signatureBase64"

    $body = @{
        client_id             = $ClientId
        scope                 = "https://graph.microsoft.com/.default"
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
        client_assertion      = $clientAssertion
        grant_type            = "client_credentials"
    }

    $response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body -ContentType "application/x-www-form-urlencoded"
    return $response.access_token
}

# Funktion: Mail versenden
function Send-LicenseMail($html) {
    try {
        $subject = "M365 Lizenzreport - $TenantName - $(Get-Date -Format 'dd.MM.yyyy')"

        $accessToken = Get-AccessTokenWithCertificate -TenantId $TenantId -ClientId $ClientId -CertThumbprint $CertificateThumbprint

        $mailBody = @{
            message = @{
                subject = $subject
                body = @{
                    contentType = "HTML"
                    content     = $html
                }
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = $MailTo
                        }
                    }
                )
            }
            saveToSentItems = $false
        }

        Invoke-RestMethod -Method POST `
            -Uri "https://graph.microsoft.com/v1.0/users/$MailFrom/sendMail" `
            -Headers @{ Authorization = "Bearer $accessToken" } `
            -Body ($mailBody | ConvertTo-Json -Depth 10 -Compress) `
            -ContentType "application/json"

        Write-Host "Mail erfolgreich via Graph gesendet an $MailTo" -ForegroundColor Green
    } catch {
        Write-Warning "Fehler beim Mailversand: $_"
    }
}

function Send-LicenseTeams {
    param (
        [string]$WebhookUrl,
        [string]$TenantName,
        $Skus
    )

    $date = Get-Date -Format "dd.MM.yyyy HH:mm"

    $cardBody = @(
        @{
            type = "TextBlock"
            size = "Large"
            weight = "Bolder"
            text = "Microsoft 365 Lizenzreport - $TenantName"
        },
        @{
            type = "TextBlock"
            text = "Stand: $date"
            isSubtle = $true
            spacing = "None"
        },
        @{
            type = "ColumnSet"
            columns = @(
                @{ type = "Column"; width = "stretch"; items = @(@{ type = "TextBlock"; text = "Lizenz"; weight = "Bolder" }) },
                @{ type = "Column"; width = "auto"; items = @(@{ type = "TextBlock"; text = "Gekauft"; weight = "Bolder" }) },
                @{ type = "Column"; width = "auto"; items = @(@{ type = "TextBlock"; text = "Verwendet"; weight = "Bolder" }) },
                @{ type = "Column"; width = "auto"; items = @(@{ type = "TextBlock"; text = "Frei %"; weight = "Bolder" }) }
            )
        }
    )

    foreach ($sku in $Skus) {
        $label = [string]$sku.SkuPartNumber
        $enabled = [int]$sku.PrepaidUnits.Enabled
        $used = [int]$sku.ConsumedUnits
        $free = $enabled - $used
        $freePercent = if ($enabled -gt 0) { [math]::Round(($free / $enabled) * 100, 1) } else { 0 }

        $color = if ($freePercent -lt 1) { "Attention" }
                 elseif ($freePercent -lt 15) { "Warning" }
                 else { "Good" }

        $cardBody += @{
            type = "ColumnSet"
            columns = @(
                @{ type = "Column"; width = "stretch"; items = @(@{ type = "TextBlock"; text = "$label" }) },
                @{ type = "Column"; width = "auto"; items = @(@{ type = "TextBlock"; text = "$enabled" }) },
                @{ type = "Column"; width = "auto"; items = @(@{ type = "TextBlock"; text = "$used" }) },
                @{ type = "Column"; width = "auto"; items = @(@{
                    type = "TextBlock";
                    text = "$freePercent%";
                    color = $color;
                    weight = "Bolder"
                }) }
            )
        }
    }

    $payload = @{
        type = "message"
        attachments = @(
            @{
                contentType = "application/vnd.microsoft.card.adaptive"
                content = @{
                    type = "AdaptiveCard"
                    version = "1.5"
                    body = $cardBody
                }
            }
        )
    }

    Invoke-RestMethod -Method Post `
        -Uri $WebhookUrl `
        -Body ($payload | ConvertTo-Json -Depth 10 -Compress) `
        -ContentType 'application/json'

    Write-Host "Adaptive Card an Teams gesendet." -ForegroundColor Green
}




# ─────────────────────────────
# Hauptlogik
# ─────────────────────────────
Set-ConsoleBuffer
Connect-MgGraphSafe

$TenantName = Get-TenantInfo
$skus = Get-LicenseData
$html = Generate-LicenseHtml -skus $skus -TenantName $TenantName

# Speichern
if ($SaveHtml) {
$html | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "HTML-Report gespeichert unter $OutputPath" -ForegroundColor Green
}
# Optional senden
if ($SendMail) {
    Send-LicenseMail -html $html
}

if ($SendTeams) {
    Send-LicenseTeams -WebhookUrl $teamsWebhook -TenantName $TenantName -Skus $skus
}