#Requires -Version 7
<#
.SYNOPSIS
  Ajoute "Maitre [Nom]," en premiere ligne de tous les Corps J0 qui ne commencent pas par "Maitre".
  Cible : Envoye J0 = false ET Corps J0 present ET ne commence pas par "Maitre".
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TOKEN   = $env:NOTION_TOKEN
$DB_ID   = '9f569df384d84b0aa4e20e192aa9da2a'
$DELAY   = 1

if (-not $TOKEN) { throw "NOTION_TOKEN non defini" }

$headers = @{
    'Authorization'  = "Bearer $TOKEN"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json'
}

# ── 1. REQUETE : non envoyes + corps non vide ─────────────────────────────────
Write-Host "Requete Notion..." -ForegroundColor Cyan

$body = @{
    filter = @{
        property = "Envoyé J0"
        checkbox = @{ equals = $false }
    }
    page_size = 100
} | ConvertTo-Json -Depth 10 -Compress

$resp  = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DB_ID/query" `
         -Method Post -Headers $headers -Body $body

$pages = @($resp.results | Where-Object {
    $c = $_.properties.'Corps J0'.rich_text
    $c -and $c.Count -gt 0 -and $c[0].text.content.Trim() -ne ''
})

Write-Host "$($pages.Count) page(s) avec Corps J0 non vide et non envoye"

# ── 2. FILTRER ceux qui ne commencent pas par "Maitre" ───────────────────────
$toFix = @($pages | Where-Object {
    $corps = $_.properties.'Corps J0'.rich_text[0].text.content
    -not ($corps.TrimStart() -match '(?i)^Ma[iî]tre')
})

Write-Host "$($toFix.Count) email(s) a corriger (sans 'Maitre' en debut)`n" -ForegroundColor Yellow

if ($toFix.Count -eq 0) {
    Write-Host "Tous les brouillons ont deja la salutation. Fin." -ForegroundColor Green
    exit 0
}

# ── 3. CORRECTION ─────────────────────────────────────────────────────────────
$ok = 0; $ko = 0

foreach ($page in $toFix) {
    $pageId = $page.id
    $nom    = $page.properties.Nom.title[0].text.content
    $corps  = $page.properties.'Corps J0'.rich_text[0].text.content

    # Extraire le nom de famille : dernier mot apres le dernier espace
    $mots = $nom.Trim() -split '\s+'
    $nomFamille = $mots[-1]

    # Si c'est un cabinet generique (ex: "CTL Avocats" -> "Avocats"), pas de nom
    $salutation = if ($nomFamille -match '^(Avocats?|Cabinet|Associes?|SCP|SELARL|SAS)$') {
        "Maitre,"
    } else {
        "Maitre $nomFamille,"
    }

    $newCorps = "$salutation`n`n$($corps.TrimStart())"

    # Limiter a 2000 caracteres (limite Notion rich_text)
    if ($newCorps.Length -gt 2000) {
        $newCorps = $newCorps.Substring(0, 1997) + "..."
    }

    $patch = @{
        properties = @{
            'Corps J0' = @{
                rich_text = @(
                    @{ text = @{ content = $newCorps } }
                )
            }
        }
    } | ConvertTo-Json -Depth 10 -Compress

    try {
        Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$pageId" `
            -Method Patch -Headers $headers -Body $patch | Out-Null
        Write-Host "OK  [$nom] -> '$salutation'" -ForegroundColor Green
        $ok++
    } catch {
        Write-Warning "ECHEC [$nom] : $_"
        $ko++
    }

    if ($DELAY -gt 0) { Start-Sleep -Milliseconds ($DELAY * 500) }
}

Write-Host "`n========================================"
Write-Host "RAPPORT fix_salutation"
Write-Host "  Corriges : $ok"
if ($ko -gt 0) { Write-Host "  Echecs   : $ko" -ForegroundColor Red }
Write-Host "========================================`n"
