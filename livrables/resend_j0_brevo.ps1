#Requires -Version 7
<#
.SYNOPSIS
  Renvoie les emails J0 via Brevo API pour tous les prospects Valide J0 = true.
  IGNORE le flag "Envoye J0" — utilise pour corriger les emails arrives en spam via IONOS.
  Prerequis : NOTION_TOKEN, IONOS_FROM_EMAIL, BREVO_API_KEY definis en variables d'env utilisateur.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── CONFIGURATION ────────────────────────────────────────────────────────────
$FROM       = $env:IONOS_FROM_EMAIL       # kamil@perflux.fr — adresse d'envoi
$API_KEY    = $env:BREVO_API_KEY          # cle API Brevo
$TOKEN      = $env:NOTION_TOKEN
$DB_ID      = '9f569df384d84b0aa4e20e192aa9da2a'
$DELAY_SEC  = 60

if (-not $FROM)     { throw "IONOS_FROM_EMAIL non definie" }
if (-not $API_KEY)  { throw "BREVO_API_KEY non definie" }
if (-not $TOKEN)    { throw "NOTION_TOKEN non defini" }

$notionHeaders = @{
    'Authorization'  = "Bearer $TOKEN"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json'
}

# ── REQUETE NOTION : tous les prospects Valide J0 = true (sans filtre Envoye J0) ──
Write-Host "RESEND J0 via Brevo — prospects Valide J0 = true + Corps J0 non vide..." -ForegroundColor Yellow
Write-Host "ATTENTION : ce script ignore le flag 'Envoye J0'. Il renvoie a tous les prospects valides." -ForegroundColor Yellow

$queryBody = @{
    filter    = @{ property = "Validé J0"; checkbox = @{ equals = $true } }
    page_size = 100
} | ConvertTo-Json -Depth 10 -Compress

$queryUrl = "https://api.notion.com/v1/databases/$DB_ID/query"
$queryResp = Invoke-RestMethod -Uri $queryUrl -Method Post -Headers $notionHeaders -Body $queryBody

$pages = @($queryResp.results | Where-Object {
    $corps = $_.properties.'Corps J0'.rich_text
    $corps -and $corps.Count -gt 0 -and $corps[0].text.content.Trim() -ne ''
})

Write-Host "$($pages.Count) prospect(s) a renvoyer" -ForegroundColor Cyan

if ($pages.Count -eq 0) {
    Write-Host "Aucun email a renvoyer. Fin." -ForegroundColor Yellow
    exit 0
}

$confirm = Read-Host "`nConfirmer le renvoi a $($pages.Count) prospects ? (oui/non)"
if ($confirm -ne 'oui') {
    Write-Host "Annule." -ForegroundColor Red
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

$brevoHeaders = @{ "api-key" = $API_KEY; "Content-Type" = "application/json" }

# ── ENVOI ────────────────────────────────────────────────────────────────────
$sentLog = @()
$total   = $pages.Count
$index   = 0

Write-Host "`nDebut : $(Get-Date -Format 'HH:mm:ss')  |  Fin estimee : $(([datetime]::Now).AddSeconds($DELAY_SEC * ($total - 1)).ToString('HH:mm:ss'))`n"

foreach ($page in $pages) {
    $index++
    $pageId = $page.id -replace '-', ''
    $pageId = "$($pageId.Substring(0,8))-$($pageId.Substring(8,4))-$($pageId.Substring(12,4))-$($pageId.Substring(16,4))-$($pageId.Substring(20))"

    $email  = $page.properties.Email.email
    $objet  = $page.properties.'Objet J0'.rich_text[0].text.content
    $corps  = $page.properties.'Corps J0'.rich_text[0].text.content
    $nom    = $page.properties.Nom.title[0].text.content

    $htmlBody = ConvertTo-EmailHtml $corps

    $brevoBody = @{
        sender      = @{ name = "Kamil Khebbache - Perflux"; email = $FROM }
        to          = @(@{ email = $email; name = $nom })
        subject     = $objet
        htmlContent = $htmlBody
    } | ConvertTo-Json -Depth 5 -Compress

    $sentOk = $false
    try {
        Invoke-RestMethod -Uri "https://api.brevo.com/v3/smtp/email" `
            -Method Post -Headers $brevoHeaders -Body $brevoBody | Out-Null
        $sentOk = $true
        $sentLog += [PSCustomObject]@{ Email = $email; Nom = $nom; Ok = $true }
        Write-Host "[$index/$total] OK   $email" -ForegroundColor Green
    } catch {
        $sentLog += [PSCustomObject]@{ Email = $email; Nom = $nom; Ok = $false; Error = $_.Exception.Message }
        Write-Warning "[$index/$total] ECHEC $email : $_"
    }

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
$ko      = @($sentLog | Where-Object { !$_.Ok }).Count
Write-Host "`n========================================"
Write-Host "RAPPORT RESEND J0 BREVO — $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "  OK     : $okCount / $total"
if ($ko -gt 0) {
    Write-Host "  Echecs ($ko) :" -ForegroundColor Red
    $sentLog | Where-Object { !$_.Ok } | ForEach-Object {
        Write-Host "    - $($_.Email) : $($_.Error)" -ForegroundColor Red
    }
}
Write-Host "========================================`n"
