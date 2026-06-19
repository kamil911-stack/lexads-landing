#Requires -Version 7
<#
.SYNOPSIS
  Envoie les emails J0 via Brevo a tous les prospects avec Corps J0 non vide + Envoye J0 = false.
  Ignore le flag "Valide J0" — couvre tous les prospects non encore contactes.
  Prerequis : NOTION_TOKEN, IONOS_FROM_EMAIL, BREVO_API_KEY definis en variables d'env.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$FROM      = $env:IONOS_FROM_EMAIL
$API_KEY   = $env:BREVO_API_KEY
$TOKEN     = $env:NOTION_TOKEN
$DB_ID     = '9f569df384d84b0aa4e20e192aa9da2a'
$DELAY_SEC = 60

if (-not $FROM)    { throw "IONOS_FROM_EMAIL non definie" }
if (-not $API_KEY) { throw "BREVO_API_KEY non definie" }
if (-not $TOKEN)   { throw "NOTION_TOKEN non defini" }

$notionHeaders = @{
    'Authorization'  = "Bearer $TOKEN"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json'
}

Write-Host "VAGUE 2 J0 — Corps J0 non vide + Envoye J0 = false..." -ForegroundColor Yellow

# Pagination Notion (max 100 par requete)
$pages    = [System.Collections.Generic.List[object]]::new()
$cursor   = $null
$hasMore  = $true

while ($hasMore) {
    $queryBody = @{
        filter    = @{
            and = @(
                @{ property = "Corps J0"; rich_text = @{ is_not_empty = $true } }
                @{ property = "Envoyé J0"; checkbox = @{ equals = $false } }
            )
        }
        page_size = 100
    }
    if ($cursor) { $queryBody.start_cursor = $cursor }

    $resp    = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DB_ID/query" `
                   -Method Post -Headers $notionHeaders `
                   -Body ($queryBody | ConvertTo-Json -Depth 10 -Compress)
    $hasMore = $resp.has_more
    $cursor  = $resp.next_cursor
    foreach ($p in $resp.results) { $pages.Add($p) }
}

Write-Host "$($pages.Count) prospect(s) a envoyer" -ForegroundColor Cyan

if ($pages.Count -eq 0) {
    Write-Host "Aucun email a envoyer. Fin." -ForegroundColor Yellow
    exit 0
}

$confirm = Read-Host "`nConfirmer l'envoi a $($pages.Count) prospects ? (oui/non)"
if ($confirm -ne 'oui') { Write-Host "Annule." -ForegroundColor Red; exit 0 }

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
$sentLog      = @()
$total        = $pages.Count
$index        = 0

Write-Host "`nDebut : $(Get-Date -Format 'HH:mm:ss')  |  Fin estimee : $(([datetime]::Now).AddSeconds($DELAY_SEC * ($total - 1)).ToString('HH:mm:ss'))`n"

foreach ($page in $pages) {
    $index++
    $rawId  = $page.id -replace '-', ''
    $pageId = "$($rawId.Substring(0,8))-$($rawId.Substring(8,4))-$($rawId.Substring(12,4))-$($rawId.Substring(16,4))-$($rawId.Substring(20))"

    $email = $page.properties.Email.email
    $nom   = $page.properties.Nom.title[0].text.content
    $objet = $page.properties.'Objet J0'.rich_text[0].text.content
    $corps = $page.properties.'Corps J0'.rich_text[0].text.content

    if (-not $email) {
        Write-Warning "[$index/$total] SKIP $nom — email manquant"
        continue
    }

    $brevoBody = @{
        sender      = @{ name = "Kamil Khebbache - Perflux"; email = $FROM }
        to          = @(@{ email = $email; name = $nom })
        subject     = $objet
        htmlContent = ConvertTo-EmailHtml $corps
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

$okCount = ($sentLog | Where-Object { $_.Ok }).Count
$ko      = @($sentLog | Where-Object { -not $_.Ok }).Count
Write-Host "`n========================================"
Write-Host "RAPPORT VAGUE 2 J0 — $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "  OK     : $okCount / $total"
if ($ko -gt 0) {
    Write-Host "  Echecs ($ko) :" -ForegroundColor Red
    $sentLog | Where-Object { -not $_.Ok } | ForEach-Object {
        Write-Host "    - $($_.Email) : $($_.Error)" -ForegroundColor Red
    }
}
Write-Host "========================================`n"
