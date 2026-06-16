#Requires -Version 7
<#
.SYNOPSIS
  Envoie les emails J0 valides via IONOS SMTP et met a jour prospects.json.
  N'envoie QUE les prospects ou seq.j0.validated=true, seq.j0.corps != '', seq.j0.sent = false.
  Prerequis : IONOS_FROM_EMAIL, IONOS_PASSWORD, PERFLUX_CRM_URL definis au niveau utilisateur.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── CONFIGURATION ────────────────────────────────────────────────────────────
$SMTP_HOST  = if ($env:IONOS_SMTP_HOST) { $env:IONOS_SMTP_HOST } else { 'smtp.ionos.fr' }
$SMTP_PORT  = 587   # STARTTLS
$FROM       = $env:IONOS_FROM_EMAIL
$PASSWORD   = $env:IONOS_PASSWORD
$CRM_URL    = if ($env:PERFLUX_CRM_URL) { $env:PERFLUX_CRM_URL.TrimEnd('/') } else { 'https://perflux-crm.netlify.app' }
$DELAY_SEC  = 150   # 2.5 minutes entre chaque envoi

if (-not $FROM)     { throw "IONOS_FROM_EMAIL non definie" }
if (-not $PASSWORD) { throw "IONOS_PASSWORD non definie" }

$jsonPath = Join-Path $PSScriptRoot 'prospects.json'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')

# ── GIT PULL (recupere les dernieres validations depuis le CRM) ──────────────
Write-Host "Git pull — recuperation des dernieres validations..." -ForegroundColor Cyan
Push-Location $repoRoot
try {
  git pull --rebase origin master 2>&1 | ForEach-Object { Write-Host "  $_" }
  Write-Host "  Pull OK" -ForegroundColor Green
} catch {
  Write-Warning "Git pull echoue : $_. Envoi avec l'etat local."
} finally {
  Pop-Location
}

# ── CHARGEMENT ET FILTRAGE ───────────────────────────────────────────────────
$prospects = Get-Content $jsonPath -Encoding UTF8 | ConvertFrom-Json

$toSend = @($prospects | Where-Object {
  $_.seq.j0.validated -eq $true -and
  ($_.seq.j0.corps -ne $null) -and ($_.seq.j0.corps -ne '') -and
  $_.seq.j0.sent -ne $true
})

Write-Host "$($toSend.Count) prospect(s) valide(s) a envoyer" -ForegroundColor Cyan

if ($toSend.Count -eq 0) {
  Write-Host "Aucun email a envoyer. Fin." -ForegroundColor Yellow
  exit 0
}

# ── HELPERS ─────────────────────────────────────────────────────────────────
function ConvertTo-EmailHtml($text, $trackUrl) {
  $safe = $text -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
  $safe = $safe -replace "(?:`r`n){2,}|(?:`n){2,}", '</p><p>'
  $safe = $safe -replace "`r`n|`n", '<br>'
  $pixel = if ($trackUrl) { "<img src=`"$trackUrl`" width=`"1`" height=`"1`" alt=`"`" style=`"display:none`">" } else { '' }
  return @"
<html><body style="font-family:Arial,sans-serif;font-size:14px;color:#333;line-height:1.6;max-width:580px">
<p>$safe</p>
$pixel
</body></html>
"@
}

# ── SMTP ────────────────────────────────────────────────────────────────────
$smtp = [System.Net.Mail.SmtpClient]::new($SMTP_HOST, $SMTP_PORT)
$smtp.EnableSsl    = $true
$smtp.Credentials = [System.Net.NetworkCredential]::new($FROM, $PASSWORD)
$smtp.Timeout      = 30000

$sentLog = @()
$total   = $toSend.Count
$index   = 0

Write-Host "Debut : $(Get-Date -Format 'HH:mm:ss')  |  Fin estimee : $(([datetime]::Now).AddSeconds($DELAY_SEC * ($total - 1)).ToString('HH:mm:ss'))`n"

foreach ($p in $toSend) {
  $index++

  $trackUrl = if ($p.notionPageId -and $CRM_URL -notmatch 'VOTRE_CRM') {
    "$CRM_URL/.netlify/functions/track?page=$($p.notionPageId)&step=j0"
  } else { $null }

  $htmlBody = ConvertTo-EmailHtml $p.seq.j0.corps $trackUrl

  $msg            = [System.Net.Mail.MailMessage]::new()
  $msg.From       = [System.Net.Mail.MailAddress]::new($FROM, 'Kamil Khebbache — Perflux')
  $msg.To.Add($p.email)
  $msg.Subject    = $p.seq.j0.objet
  $msg.Body       = $htmlBody
  $msg.IsBodyHtml = $true

  try {
    $smtp.Send($msg)
    $sentAt           = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
    $p.seq.j0.sent    = $true
    $p.seq.j0.sentAt  = $sentAt
    if ($p.stage -eq 'nouveaux') { $p.stage = 'sequence' }
    $sentLog += [PSCustomObject]@{ Email=$p.email; SentAt=$sentAt; Objet=$p.seq.j0.objet; Ok=$true }
    Write-Host "[$index/$total] OK   $($p.email)" -ForegroundColor Green
  } catch {
    $sentLog += [PSCustomObject]@{ Email=$p.email; SentAt=$null; Objet=$p.seq.j0.objet; Ok=$false; Error=$_.Exception.Message }
    Write-Warning "[$index/$total] ECHEC $($p.email) : $_"
  }
  $msg.Dispose()

  if ($index -lt $total) {
    Write-Host "  Attente $([int]($DELAY_SEC / 60)) min..." -ForegroundColor DarkGray
    Start-Sleep -Seconds $DELAY_SEC
  }
}
$smtp.Dispose()

# ── MISE A JOUR prospects.json ───────────────────────────────────────────────
$prospects | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
Write-Host "`nprospects.json mis a jour" -ForegroundColor Green

# ── GIT COMMIT + PUSH ────────────────────────────────────────────────────────
$okCount = ($sentLog | Where-Object { $_.Ok }).Count
Write-Host "Commit + push..." -ForegroundColor Cyan
Push-Location $repoRoot
try {
  git add livrables/crm-site/prospects.json
  git commit -m "J0 envoye $(Get-Date -Format 'yyyy-MM-dd HH:mm') — $okCount OK"
  git push
  Write-Host "  Push OK" -ForegroundColor Green
} catch {
  Write-Warning "Git push echoue. Faites le push manuellement."
} finally {
  Pop-Location
}

# ── RAPPORT ──────────────────────────────────────────────────────────────────
$ko = ($sentLog | Where-Object { !$_.Ok }).Count
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
