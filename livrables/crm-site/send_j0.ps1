#Requires -Version 7
<#
.SYNOPSIS
  Envoie les 18 emails J0 (Emma + Sami) via IONOS SMTP et met a jour prospects.json.
  Prerequis : variables d'environnement IONOS_FROM_EMAIL, IONOS_PASSWORD, IONOS_SMTP_HOST,
              NOTION_API_KEY, PERFLUX_CRM_URL definies au niveau utilisateur/systeme.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ── CONFIGURATION ───────────────────────────────────────────────────────────
$SMTP_HOST   = if ($env:IONOS_SMTP_HOST)  { $env:IONOS_SMTP_HOST }  else { 'smtp.ionos.fr' }
$SMTP_PORT   = 587   # STARTTLS — IONOS supporte 587 et 465
$FROM        = $env:IONOS_FROM_EMAIL
$PASSWORD    = $env:IONOS_PASSWORD
$NOTION_KEY  = $env:NOTION_API_KEY
$DB_ID       = '9f569df3-84d8-4b0a-a4e2-0e192aa9da2a'
$CRM_URL     = if ($env:PERFLUX_CRM_URL) { $env:PERFLUX_CRM_URL.TrimEnd('/') } else { 'https://VOTRE_CRM.netlify.app' }
$DELAY_MIN   = 4   # minutes entre chaque envoi

if (-not $FROM)       { throw "IONOS_FROM_EMAIL non definie" }
if (-not $PASSWORD)   { throw "IONOS_PASSWORD non definie" }
if (-not $NOTION_KEY) { throw "NOTION_API_KEY non definie" }

# ── HELPERS ─────────────────────────────────────────────────────────────────
function Invoke-NotionApi($path, $method = 'GET', $body = $null) {
  $h = @{
    'Authorization'   = "Bearer $NOTION_KEY"
    'Notion-Version'  = '2022-06-28'
    'Content-Type'    = 'application/json'
  }
  $p = @{ Uri = "https://api.notion.com$path"; Method = $method; Headers = $h }
  if ($body) { $p.Body = ($body | ConvertTo-Json -Depth 6 -Compress) }
  return Invoke-RestMethod @p
}

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

# ── ETAPE 1 : Ajout proprietes Notion (idempotent) ──────────────────────────
Write-Host "Ajout proprietes Notion J0/J3/J7/J14 ouvert..." -ForegroundColor Cyan
try {
  $schema = @{
    properties = @{
      'J0 ouvert'  = @{ checkbox = @{} }
      'J3 ouvert'  = @{ checkbox = @{} }
      'J7 ouvert'  = @{ checkbox = @{} }
      'J14 ouvert' = @{ checkbox = @{} }
    }
  }
  Invoke-NotionApi "/v1/databases/$DB_ID" 'PATCH' $schema | Out-Null
  Write-Host "  OK — proprietes ajoutees/confirmees" -ForegroundColor Green
} catch {
  Write-Warning "Impossible de mettre a jour le schema Notion : $_"
}

# ── ETAPE 2 : Recuperer les page IDs Notion ──────────────────────────────────
Write-Host "Recuperation des pages Notion..." -ForegroundColor Cyan
$pages = @()
$cursor = $null
do {
  $q = @{ page_size = 100 }
  if ($cursor) { $q.start_cursor = $cursor }
  $r = Invoke-NotionApi "/v1/databases/$DB_ID/query" 'POST' $q
  $pages += $r.results
  $cursor = if ($r.has_more) { $r.next_cursor } else { $null }
} while ($cursor)

$pageIdMap = @{}
foreach ($p in $pages) {
  $email = $p.properties.Email.email
  if ($email) { $pageIdMap[$email] = $p.id }
}
Write-Host "  $($pageIdMap.Count) prospects trouves dans Notion" -ForegroundColor Green

# ── ETAPE 3 : Liste des 18 emails J0 ────────────────────────────────────────
$emails = @(

  # ===== GROUPE EMMA (9 prospects) — pitch direct + ROI + Calendly =====

  @{
    Email  = 'acharnois@charnois-avocat.fr'
    Groupe = 'emma'
    Objet  = 'Votre fiche Google Vincennes — une question'
    Corps  = @'
Maître Charnois,

Votre cabinet affiche 5,0/5 sur Google Maps à Vincennes — c'est rare, et c'est un signal de confiance fort.

Mais quand un particulier cherche "avocat droit de la famille Vincennes" sur Google, votre fiche n'apparaît pas dans les annonces payantes. Vos confrères qui s'y trouvent captent des dossiers que vous ne voyez jamais.

Chez Perflux, on gère exclusivement des campagnes Google Ads pour avocats : un dossier famille en Île-de-France représente entre 2 000 et 4 000 € de CA. Avec un budget ciblé sur votre zone, vous récupérez ces dossiers.

15 minutes suffisent pour voir si c'est pertinent pour votre cabinet.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'bonzoug@orange.fr'
    Groupe = 'emma'
    Objet  = 'Votre cabinet Villejuif — visibilité Google'
    Corps  = @'
Maître Bonzougou,

J'ai consulté votre site maitre-bonzougou.fr : droit de la famille, contrats, immobilier à Villejuif — un profil généraliste bien positionné sur une commune dense.

Ce que j'observe : aucune annonce Google Ads sur "avocat droit de la famille Villejuif" ni "avocat divorce 94". Ces requêtes existent et partent chez des confrères d'autres villes.

Perflux gère des campagnes Google Ads uniquement pour avocats. Un dossier famille ou immobilier représente entre 1 500 et 4 000 € de CA. Avec votre offre multi-matières, chaque clic est une opportunité de dossier.

15 minutes pour valider si c'est pertinent pour votre cabinet.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'avocatsimaogomes@gmail.com'
    Groupe = 'emma'
    Objet  = 'Avocat immobilier Arpajon — opportunité Google'
    Corps  = @'
Maître Simao-Gomes,

Arpajon et l'Essonne sud ont peu d'avocats en droit immobilier actifs sur Google Ads. C'est une opportunité directe pour votre cabinet.

Les particuliers cherchent "avocat droit immobilier Essonne" ou "avocat achat immobilier 91" — ces requêtes sont peu disputées, et un dossier immobilier représente entre 1 500 et 3 000 € de CA.

Chez Perflux, on crée des campagnes Google Ads exclusivement pour avocats. Votre site est déjà en place — il suffit d'y envoyer les bons visiteurs.

15 minutes suffisent pour évaluer le potentiel sur votre zone.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'avocat@cdanielian.com'
    Groupe = 'emma'
    Objet  = 'Votre site danielian-avocat.com — une observation'
    Corps  = @'
Maître Danielian,

J'ai regardé votre site danielian-avocat.com — il est propre, professionnel, et cible bien les dossiers famille en Essonne.

Le problème : quand quelqu'un cherche "avocat droit de la famille Évry" sur Google, votre site n'apparaît pas dans les résultats payants. Ce sont des dossiers qui partent chez d'autres.

Perflux gère des campagnes Google Ads exclusivement pour avocats. En droit de la famille, un dossier représente entre 2 000 et 4 000 € de CA. Avec un budget ciblé sur Évry et l'Essonne, vous récupérez ces dossiers.

15 minutes suffisent pour voir si c'est adapté à votre profil.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'contact@bellot-avocat.com'
    Groupe = 'emma'
    Objet  = 'Votre cabinet Vitry — et Google Ads'
    Corps  = @'
Maître Bellot,

Votre cabinet bellot-avocat.com est bien positionné à Vitry-sur-Seine, mais les annonces Google Ads sur "avocat divorce Vitry" ou "avocat droit de la famille Val-de-Marne" sont occupées par des confrères d'autres villes.

Un dossier de droit de la famille représente entre 2 000 et 4 000 € de CA — et ces requêtes restent peu disputées dans votre zone.

Perflux gère des campagnes Google Ads exclusivement pour avocats. Votre site est là, il faut juste y envoyer les bons clients.

15 minutes pour voir si ça colle avec votre activité.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'norman@delain-avocat.com'
    Groupe = 'emma'
    Objet  = 'Norman Delain — votre niche presse et Google Ads'
    Corps  = @'
Maître Delain,

J'ai vu votre profil LinkedIn et votre cabinet delain-avocat.com : droit pénal et droit de la presse à Évry — une combinaison rare, à forte valeur.

Ce qui m'a frappé : aucune annonce Google Ads sur "avocat pénal Essonne" ou "avocat droit de la presse Île-de-France". Ces requêtes existent, les dossiers pénaux représentent entre 2 500 et 6 000 € de CA, et vos confrères n'y sont pas.

Votre présence LinkedIn est un atout. Les Google Ads complètent là où LinkedIn n'atteint pas : les justiciables en urgence, qui cherchent sur Google à 23h.

15 minutes suffisent pour en parler.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'nerrant.stephane@gmail.com'
    Groupe = 'emma'
    Objet  = 'Maître Nerrant — fiscaliste et Google Ads'
    Corps  = @'
Maître Nerrant,

Votre profil m'a intrigué : avocat fiscal et civil depuis plus de 20 ans à Morsang-sur-Orge, membre de l'IACF et du Club Business Essonne — un réseau solide.

Mais sur Google, les requêtes "avocat fiscaliste Essonne" ou "avocat droit fiscal 91" ne renvoient aucune annonce de votre cabinet. Ces recherches viennent de professionnels et particuliers avec des enjeux élevés — les dossiers fiscaux sont parmi les plus rentables.

Perflux gère exclusivement des campagnes Google Ads pour avocats. Ce serait un levier complémentaire à votre réseau, pas un remplacement.

15 minutes pour voir si ça a du sens.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'ldeleenheer.avocat@gmail.com'
    Groupe = 'emma'
    Objet  = 'Votre blog droit de la famille — une observation'
    Corps  = @'
Maître de Leenheer,

J'ai lu vos articles sur le divorce en Val-de-Marne et la location Airbnb — bon contenu, publié en 2020. Vous avez clairement commencé à investir dans le digital.

Le blog s'est arrêté, mais les recherches Google, elles, n'ont pas arrêté. Quelqu'un qui tape "avocat divorce Saint-Maur" aujourd'hui ne voit pas votre cabinet.

Les Google Ads donnent des résultats en 48h là où le référencement organique prend des mois. Et en droit de la famille, un dossier représente entre 2 000 et 4 000 € de CA.

Ça vaut 15 minutes d'appel.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'aurelie.dussud@adavocat.fr'
    Groupe = 'emma'
    Objet  = 'Cabinet Dussud Le Perreux — et Google Ads'
    Corps  = @'
Maître Dussud,

Médiatrice certifiée IFOMENE et avocate en droit civil, pénal et baux à Le Perreux-sur-Marne — votre profil est plus complet que la plupart.

Ce qui manque : une présence sur les annonces Google. Quand un justiciable cherche "avocat baux Le Perreux" ou "avocat pénal Val-de-Marne", votre site dussud-avocat.fr n'apparaît pas dans les résultats payants.

Perflux gère des campagnes Google Ads exclusivement pour avocats. Dans votre zone, ces requêtes sont peu disputées — et un dossier représente entre 1 500 et 4 000 € de CA selon la matière.

15 minutes pour voir ce que ça peut apporter.

Réservez directement : https://calendly.com/kamil-perflux/30min

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  # ===== GROUPE SAMI (9 prospects) — audit gratuit + "confirmez par retour" =====

  @{
    Email  = 'cabinet@avocat-bacle.fr'
    Groupe = 'sami'
    Objet  = 'Votre cabinet Joinville — audit Google Ads gratuit'
    Corps  = @'
Maître Baclé,

J'ai regardé votre cabinet sur bacle-avocat.fr : droit immobilier et droit de la famille à Joinville-le-Pont. Votre zone n'est pas saturée sur Google Ads — c'est une fenêtre à exploiter.

Je réalise des audits gratuits de visibilité Google pour les cabinets que je sélectionne. En 30 minutes, vous savez exactement quelles requêtes vos confrères utilisent pour capter des dossiers dans votre zone.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'thibolot@gmail.com'
    Groupe = 'sami'
    Objet  = 'Votre cabinet Créteil — audit visibilité Google'
    Corps  = @'
Maître Thibolot,

J'ai consulté votre site avocat-thibolot.com : droit de la famille à Créteil. Les requêtes "avocat divorce Créteil" et "avocat garde enfant 94" sont très peu occupées sur Google Ads — un cabinet bien positionné y prend des dossiers chaque semaine.

Je réalise des audits gratuits de visibilité pour les cabinets que je sélectionne. En 30 minutes, vous avez le tableau exact de la concurrence dans votre zone.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'me.masson.avocat@gmail.com'
    Groupe = 'sami'
    Objet  = 'Votre cabinet Créteil — audit Google Ads gratuit'
    Corps  = @'
Maître Masson,

J'ai regardé votre site avocat-masson.fr : droit des contrats et droit civil à Créteil. Vos confrères spécialisés dans votre domaine ne sont quasiment pas présents sur Google Ads dans le Val-de-Marne — c'est une position rare.

Je réalise des audits gratuits pour des cabinets sélectionnés. En 30 minutes, vous voyez exactement quelles requêtes vous permettraient de capter des dossiers sans toucher à votre développement actuel.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'contact@yanngre.com'
    Groupe = 'sami'
    Objet  = 'Cabinet Gré Créteil — audit Google Ads gratuit'
    Corps  = @'
Maître Gré,

J'ai consulté votre site yanngre.com : droit civil et droit des contrats à Créteil. C'est une niche que les agences générales n'adressent pas — et sur Google Ads, vos confrères spécialisés dans le même domaine sont absents.

Je réalise des audits de visibilité Google gratuits pour les cabinets que je sélectionne. En 30 minutes, vous savez précisément ce que vous ratez et ce que vous pouvez capter.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'chemla.avocat@bbox.fr'
    Groupe = 'sami'
    Objet  = 'Cabinet Chemla Vitry — audit visibilité Google'
    Corps  = @'
Maître Chemla,

J'ai regardé votre site avocat-chemla.fr : droit de la famille à Vitry-sur-Seine. Sur Google Ads, les requêtes liées à votre spécialité dans votre zone sont presque entièrement libres — c'est inhabituel pour une commune de cette taille.

Je réalise des audits gratuits pour des cabinets sélectionnés. En 30 minutes, vous avez la carte exacte de vos opportunités Google Ads à Vitry et dans le 94.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'contact@cabinet-mbavocats.fr'
    Groupe = 'sami'
    Objet  = 'Cabinet MB Avocats Évry — audit Google Ads gratuit'
    Corps  = @'
Maître,

J'ai consulté votre site cabinet-mbavocats.fr : trois avocats, deux bureaux à Évry et Fontainebleau, consultations vidéo disponibles — un cabinet qui a déjà fait le choix du digital.

Ce que j'ai noté : aucune campagne Google Ads visible sur vos deux zones. Avec deux implantations géographiques, une campagne bien ciblée est un levier direct de dossiers entrants.

Je réalise des audits gratuits pour des cabinets sélectionnés. En 30 minutes, vous voyez le potentiel exact.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'isabelle.paris@avocat-conseil-91.fr'
    Groupe = 'sami'
    Objet  = 'Cabinet Paris Évry — audit Google Ads gratuit'
    Corps  = @'
Maître Paris,

J'ai consulté cabinetavocat-isabelleparis.fr : plus de 30 ans d'ancrage à Évry, profil généraliste droit civil — famille, contrats, immobilier, commercial. Un cabinet établi.

Ce qui m'a frappé : aucune annonce Google Ads sur vos domaines dans votre zone. Votre réseau de recommandations fonctionne — mais les dossiers qui arrivent via Google partent ailleurs.

Je réalise des audits gratuits de visibilité pour des cabinets sélectionnés. En 30 minutes, vous voyez exactement ce qui vous échappe.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'contact@debrenne-dehay-avocats.fr'
    Groupe = 'sami'
    Objet  = 'Cabinet Debrenne-Dehay — audit Google Ads'
    Corps  = @'
Maître,

J'ai consulté votre site debrenne-dehay-avocats.fr : deux avocats associés, deux bureaux à Créteil et Vitry-sur-Seine, spécialités complémentaires dont le droit pénal et administratif.

Aucune annonce Google Ads n'est active sur "avocat pénal Créteil" ni "avocat droit administratif Val-de-Marne". Ces requêtes existent et un cabinet avec deux implantations géographiques les exploite naturellement mieux qu'un cabinet solo.

Je réalise des audits gratuits pour des cabinets sélectionnés. En 30 minutes, vous avez le diagnostic.

Intéressé ? Confirmez par retour.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }

  @{
    Email  = 'alexandra.lesergent@wanadoo.fr'
    Groupe = 'sami'
    Objet  = 'Cabinet Le Sergent Saint-Maur — audit Google Ads'
    Corps  = @'
Maître Le Sergent,

J'ai consulté votre site lesergent-alexandra.fr : inscrite au barreau du Val-de-Marne depuis 2004, ancienne enseignante à l'EFB de Paris — un profil de référence dans votre barreau.

Ce que j'observe : aucune visibilité Google Ads sur "avocat droit de la famille Saint-Maur" ni "avocat 94". Vingt-deux ans d'ancrage local — mais les dossiers qui arrivent via Google partent chez d'autres.

Je réalise des audits gratuits pour des cabinets sélectionnés. Confirmez par retour si vous souhaitez y participer.

Kamil Khebbache
Fondateur — Perflux
07 66 47 03 57
perflux.fr
'@
  }
)

# ── ETAPE 4 : Envoi des emails ───────────────────────────────────────────────
$smtp = [System.Net.Mail.SmtpClient]::new($SMTP_HOST, $SMTP_PORT)
$smtp.EnableSsl    = $true
$smtp.Credentials = [System.Net.NetworkCredential]::new($FROM, $PASSWORD)
$smtp.Timeout      = 30000

$sentLog  = @()
$total    = $emails.Count
$index    = 0

Write-Host "`nDemarrage envoi — $total emails — intervalle $DELAY_MIN min" -ForegroundColor Cyan
Write-Host "Debut : $(Get-Date -Format 'HH:mm:ss')  |  Fin estimee : $(([datetime]::Now).AddMinutes($DELAY_MIN * ($total - 1)).ToString('HH:mm:ss'))`n"

foreach ($e in $emails) {
  $index++
  $notionPageId = $pageIdMap[$e.Email]
  $trackUrl = if ($notionPageId -and $CRM_URL -notmatch 'VOTRE_CRM') {
    "$CRM_URL/.netlify/functions/track?page=$notionPageId&step=j0"
  } else { $null }

  $htmlBody = ConvertTo-EmailHtml $e.Corps $trackUrl

  $msg            = [System.Net.Mail.MailMessage]::new()
  $msg.From       = [System.Net.Mail.MailAddress]::new($FROM, 'Kamil Khebbache — Perflux')
  $msg.To.Add($e.Email)
  $msg.Subject    = $e.Objet
  $msg.Body       = $htmlBody
  $msg.IsBodyHtml = $true

  try {
    $smtp.Send($msg)
    $sentAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss.fffZ')
    $sentLog += [PSCustomObject]@{ Email = $e.Email; SentAt = $sentAt; Objet = $e.Objet; Ok = $true }
    Write-Host "[$index/$total] OK  $($e.Email)  [$($e.Groupe.ToUpper())]" -ForegroundColor Green
  } catch {
    $sentLog += [PSCustomObject]@{ Email = $e.Email; SentAt = $null; Objet = $e.Objet; Ok = $false; Error = $_.Exception.Message }
    Write-Warning "[$index/$total] ECHEC $($e.Email) : $_"
  }
  $msg.Dispose()

  if ($index -lt $total) {
    Write-Host "  Attente $DELAY_MIN min..." -ForegroundColor DarkGray
    Start-Sleep -Seconds ($DELAY_MIN * 60)
  }
}
$smtp.Dispose()

# ── ETAPE 5 : Mise a jour prospects.json ────────────────────────────────────
Write-Host "`nMise a jour prospects.json..." -ForegroundColor Cyan
$jsonPath = Join-Path $PSScriptRoot 'prospects.json'
$prospects = Get-Content $jsonPath -Encoding UTF8 | ConvertFrom-Json

foreach ($log in $sentLog | Where-Object { $_.Ok }) {
  $p = $prospects | Where-Object { $_.email -eq $log.Email }
  if ($p) {
    $p.seq.j0.sent   = $true
    $p.seq.j0.sentAt = $log.SentAt
    $p.seq.j0.objet  = $log.Objet
    if ($p.stage -eq 'nouveaux') { $p.stage = 'sequence' }
  }
}
$prospects | ConvertTo-Json -Depth 10 | Set-Content $jsonPath -Encoding UTF8
Write-Host "  prospects.json mis a jour" -ForegroundColor Green

# ── ETAPE 6 : Git commit + push ──────────────────────────────────────────────
Write-Host "`nCommit + push..." -ForegroundColor Cyan
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
Push-Location $repoRoot
try {
  git add livrables/crm-site/prospects.json
  git commit -m "Emma+Sami: J0 envoye $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
  git push
  Write-Host "  Push OK" -ForegroundColor Green
} catch {
  Write-Warning "Git push echoue : $_. Faites le push manuellement."
} finally {
  Pop-Location
}

# ── RAPPORT FINAL ────────────────────────────────────────────────────────────
$ok  = ($sentLog | Where-Object { $_.Ok }).Count
$ko  = ($sentLog | Where-Object { !$_.Ok }).Count
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "RAPPORT J0 — $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
Write-Host "  Envoyes avec succes : $ok / $total"
if ($ko -gt 0) {
  Write-Host "  Echecs ($ko) :" -ForegroundColor Red
  $sentLog | Where-Object { !$_.Ok } | ForEach-Object { Write-Host "    - $($_.Email) : $($_.Error)" -ForegroundColor Red }
}
Write-Host "========================================`n" -ForegroundColor Cyan
