#Requires -Version 7
<#
.SYNOPSIS
  Envoie les emails J0 via IONOS SMTP et met a jour Notion directement.
  Filtre : "Valide J0" = true ET "Envoye J0" = false ET Corps J0 non vide.
  Prerequis : NOTION_TOKEN, IONOS_FROM_EMAIL, IONOS_PASSWORD definis en variables d'env utilisateur.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── CONFIGURATION ────────────────────────────────────────────────────────────
$SMTP_HOST  = if ($env:IONOS_SMTP_HOST) { $env:IONOS_SMTP_HOST } else { 'smtp.ionos.fr' }
$SMTP_PORT  = 587
$FROM       = $env:IONOS_FROM_EMAIL
$PASSWORD   = $env:IONOS_PASSWORD
$TOKEN      = $env:NOTION_TOKEN
$DB_ID      = '9f569df384d84b0aa4e20e192aa9da2a'
$DELAY_SEC  = 150

if (-not $FROM)     { throw "IONOS_FROM_EMAIL non definie" }
if (-not $PASSWORD) { throw "IONOS_PASSWORD non definie" }
if (-not $TOKEN)    { throw "NOTION_TOKEN non defini" }

$notionHeaders = @{
    'Authorization'  = "Bearer $TOKEN"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json'
}

# ── REQUETE NOTION : prospects a envoyer ─────────────────────────────────────
Write-Host "Requete Notion — prospects Valide J0 = true + Envoye J0 = false..." -ForegroundColor Cyan

$queryBody = @{
    filter = @{
        and = @(
            @{ property = "Validé J0"; checkbox = @{ equals = $true } }
            @{ property = "Envoyé J0"; checkbox = @{ equals = $false } }
        )
    }
    page_size = 100
} | ConvertTo-Json -Depth 10 -Compress

$queryUrl = "https://api.notion.com/v1/databases/$DB_ID/query"
$queryResp = Invoke-RestMethod -Uri $queryUrl -Method Post -Headers $notionHeaders -Body $queryBody

$pages = @($queryResp.results | Where-Object {
    $corps = $_.properties.'Corps J0'.rich_text
    $corps -and $corps.Count -gt 0 -and $corps[0].text.content.Trim() -ne ''
})

Write-Host "$($pages.Count) prospect(s) a envoyer" -ForegroundColor Cyan

if ($pages.Count -eq 0) {
    Write-Host "Aucun email a envoyer. Fin." -ForegroundColor Yellow
    exit 0
}

# ── HELPER HTML ──────────────────────────────────────────────────────────────
function ConvertTo-EmailHtml($text) {
    $safe = $text -replace '&', '&amp;' -replace '<', '&lt;' -replace '>', '&gt;'
    $safe = $safe -replace "(?:`r`n){2,}|(?:`n){2,}", '</p><p>'
    $safe = $safe -replace "`r`n|`n", '<br>'
    return @"
<html><body style="font-family:Arial,sans-serif;font-size:14px;color:#333;line-height:1.6;max-width:580px">
<p>$safe</p>
</body></html>
"@
}

# ── ENVOI ────────────────────────────────────────────────────────────────────
$sentLog = @()
$total   = $pages.Count
$index   = 0

Write-Host "Debut : $(Get-Date -Format 'HH:mm:ss')  |  Fin estimee : $(([datetime]::Now).AddSeconds($DELAY_SEC * ($total - 1)).ToString('HH:mm:ss'))`n"

foreach ($page in $pages) {
    $index++
    $pageId = $page.id -replace '-', ''
    $pageId = "$($pageId.Substring(0,8))-$($pageId.Substring(8,4))-$($pageId.Substring(12,4))-$($pageId.Substring(16,4))-$($pageId.Substring(20))"

    $email  = $page.properties.Email.email
    $objet  = $page.properties.'Objet J0'.rich_text[0].text.content
    $corps  = $page.properties.'Corps J0'.rich_text[0].text.content
    $nom    = $page.properties.Nom.title[0].text.content

    $htmlBody = ConvertTo-EmailHtml $corps

    $msg            = [System.Net.Mail.MailMessage]::new()
    $msg.From       = [System.Net.Mail.MailAddress]::new($FROM, 'Kamil Khebbache — Perflux')
    $msg.To.Add($email)
    $msg.Subject    = $objet
    $msg.Body       = $htmlBody
    $msg.IsBodyHtml = $true

    $smtp              = [System.Net.Mail.SmtpClient]::new($SMTP_HOST, $SMTP_PORT)
    $smtp.EnableSsl    = $true
    $smtp.Credentials  = [System.Net.NetworkCredential]::new($FROM, $PASSWORD)
    $smtp.Timeout      = 30000

    $sentOk = $false
    try {
        $smtp.Send($msg)
        $sentOk = $true
        $sentLog += [PSCustomObject]@{ Email = $email; Nom = $nom; Ok = $true }
        Write-Host "[$index/$total] OK   $email" -ForegroundColor Green
    } catch {
        $sentLog += [PSCustomObject]@{ Email = $email; Nom = $nom; Ok = $false; Error = $_.Exception.Message }
        Write-Warning "[$index/$total] ECHEC $email : $_"
    }
    $msg.Dispose()
    $smtp.Dispose()

    # ── MISE A JOUR NOTION ──────────────────────────────────────────────────
    if ($sentOk) {
        $updateBody = @{
            properties = @{
                "Envoyé J0" = @{ checkbox = $true }
                "Statut"    = @{ select = @{ name = "Contacté" } }
            }
        } | ConvertTo-Json -Depth 5 -Compress

        try {
            Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$pageId" `
                -Method Patch -Headers $notionHeaders -Body $updateBody | Out-Null
        } catch {
            Write-Warning "  Notion non mis a jour pour $email : $_"
        }
    }

    if ($index -lt $total) {
        Write-Host "  Attente $([int]($DELAY_SEC / 60)) min..." -ForegroundColor DarkGray
        Start-Sleep -Seconds $DELAY_SEC
    }
}

# ── RAPPORT ──────────────────────────────────────────────────────────────────
$okCount = ($sentLog | Where-Object { $_.Ok }).Count
$ko      = ($sentLog | Where-Object { !$_.Ok }).Count
Write-Host "`n========================================"
Write-Host "RAPPORT J0 — $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "  OK     : $okCount / $total"
if ($ko -gt 0) {
    Write-Host "  Echecs ($ko) :" -ForegroundColor Red
    $sentLog | Where-Object { !$_.Ok } | ForEach-Object {
        Write-Host "    - $($_.Email) : $($_.Error)" -ForegroundColor Red
    }
}
Write-Host "========================================`n"
