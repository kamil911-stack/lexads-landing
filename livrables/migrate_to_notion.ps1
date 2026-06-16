#Requires -Version 7
<#
.SYNOPSIS
  Migration unique : injecte Groupe, Tier, Objet J0, Corps J0, Valide J0, Envoye J0
  dans les 31 fiches Notion qui ont deja un notionPageId dans prospects.json.
  A lancer UNE SEULE FOIS puis supprimer.
  Prerequis : NOTION_TOKEN defini en variable d'environnement utilisateur.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TOKEN = $env:NOTION_TOKEN
if (-not $TOKEN) { throw "NOTION_TOKEN non defini. Lance : [System.Environment]::SetEnvironmentVariable('NOTION_TOKEN','secret_xxx','User')" }

$JSON_PATH = Join-Path $PSScriptRoot "crm-site\prospects.json"
$prospects  = Get-Content $JSON_PATH -Encoding UTF8 | ConvertFrom-Json
$toUpdate   = @($prospects | Where-Object { $_.notionPageId })

Write-Host "$($toUpdate.Count) prospects a mettre a jour dans Notion" -ForegroundColor Cyan

$headers = @{
    'Authorization'  = "Bearer $TOKEN"
    'Notion-Version' = '2022-06-28'
    'Content-Type'   = 'application/json'
}

$ok = 0; $ko = 0

foreach ($p in $toUpdate) {
    $groupe = if ($p.groupe -eq 'emma') { 'Emma' } else { 'Sami' }
    $tier   = [int]$p.tier
    $objet  = $p.seq.j0.objet
    $corps  = $p.seq.j0.corps
    $valide = ($p.seq.j0.validated -eq $true)
    $envoye = ($p.seq.j0.sent -eq $true)

    $props = [ordered]@{
        'Groupe'     = @{ select    = @{ name = $groupe } }
        'Tier'       = @{ number    = $tier }
        'Objet J0'   = @{ rich_text = @(@{ text = @{ content = $objet } }) }
        'Corps J0'   = @{ rich_text = @(@{ text = @{ content = $corps } }) }
        "Validé J0" = @{ checkbox = $valide }
        "Envoyé J0" = @{ checkbox = $envoye }
    }

    if ($envoye) {
        $props['Statut'] = @{ select = @{ name = "Contacté" } }
    }

    $body = @{ properties = $props } | ConvertTo-Json -Depth 10 -Compress

    try {
        $url = "https://api.notion.com/v1/pages/$($p.notionPageId)"
        Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
        Write-Host "  OK  $($p.nom)" -ForegroundColor Green
        $ok++
    } catch {
        Write-Warning "  KO  $($p.nom) : $_"
        $ko++
    }

    Start-Sleep -Milliseconds 350
}

Write-Host "`nMigration terminee : $ok OK, $ko echecs" -ForegroundColor Cyan
if ($ko -eq 0) {
    Write-Host "Tu peux supprimer ce script." -ForegroundColor Yellow
}
