# Workspace History

> Journal chronologique de toutes les sessions et décisions importantes.
> Le plus récent en haut. Mis à jour automatiquement par Claude.
>
> **Comment ça marche :** Quand je lance la commande `/update` après une session importante, ou quand je raconte un changement significatif, Claude ajoute une entrée ici automatiquement. Je n'ai pas à écrire ce fichier manuellement.

---

## 2026-06-16

### Migration CRM → Notion pure + règle "Maître [Nom]" obligatoire

**CRM supprimé**
- livrables/crm-site/, prospects.json et deploy-crm.yml supprimés
- Notion "Prospects Perflux" = seule source de vérité (ID : 9f569df3...)

**Infrastructure mise à jour**
- send_j0.ps1 réécrit dans livrables/ : lit Notion (Validé J0=true + Envoyé J0=false), envoie via IONOS port 587 STARTTLS, met à jour Notion après chaque envoi
- NOTION_TOKEN ajouté dans settings.json pour les scripts PowerShell locaux
- Agents Hunter/Emma/Sami : toutes les écritures vont dans Notion via MCP

**Règle "Maître [Nom]" non négociable**
- closer.md et sami.md : règle absolue — tout email commence par "Maître [Nom]," sur la première ligne seule, suivi d'une ligne vide, sans exception
- 19 brouillons existants corrigés dans Notion via fix_salutation.ps1 (19/19 OK)

---

## 2026-06-15 (soir)

### Système brouillons + validation + envoi générique Perflux

**CRM — brouillons et validation**
- 18 emails J0 rédigés et intégrés dans prospects.json (corps + objet personnalisés par prospect)
- Onglet "Séquence emails" dans le CRM : affiche le brouillon en jaune, bouton "Valider / Annuler validation" par email
- validate.js (Netlify Function) : écrit validated=true/false dans prospects.json via GitHub API
- GITHUB_TOKEN injecté dans Netlify à chaque deploy via GitHub Actions
- Merge Source 1 mis à jour : corps/objet/validated toujours synchronisés depuis prospects.json
- Bouton "Vider cache" ajouté dans la toolbar pour forcer le rechargement depuis prospects.json

**Script d'envoi générique**
- send_j0.ps1 réécrit : git pull au démarrage, filtre validated=true + corps non vide + not sent, envoie via IONOS SMTP port 587 STARTTLS, push après envoi
- Pixel de tracking open (track.js) intégré pour les 8 prospects avec notionPageId
- Tâches Task Scheduler : Perflux-J0-Send (9h) et Perflux-J0-Send-15h (15h) créées mais désactivées — envoi sur go explicite de Kamil uniquement

**Reprogrammation des agents**
- Hunter : 2h03 lun-ven (était 8h)
- Emma : 4h17 lun-ven — brouillons groupe emma dans prospects.json + push
- Sami : 4h37 lun-ven — brouillons groupe sami dans prospects.json + push
- closer.md et sami.md mis à jour : étape 3 = écrire dans prospects.json + push avant de notifier Kamil

**État à la fin de la session**
- 18 emails rédigés, 0 envoyé — Kamil doit valider dans le CRM puis donner son go
- Bug d'affichage CRM en cours de résolution (cache localStorage / deploy Netlify)
- Prochaine action : demain matin, vider cache CRM, lire et valider les 8 Tier 1 en premier, donner le go avant 9h

---

## 2026-06-15

### Automatisation complète du pipeline prospection Perflux

**CRM web app**
- CRM kanban déployé sur Netlify (livrables/crm-site/) avec 5 colonnes : Nouveaux / Contactés / Intéressés / RDV / Lost
- Netlify Function prospects.js : fetch temps réel depuis Notion sans rebuild
- Auto-deploy via GitHub Actions (.github/workflows/deploy-crm.yml) déclenché sur push crm-site/

**Agents schedulés**
- Hunter (Alex) schedulé Lun-Ven 8h Paris — routine ID : trig_01CUt82bVWd8veP716A27FZy
- Emma schedulée Lun-Ven 9h Paris en mode brouillon — routine ID : trig_01MVJ2FD3UEh4AE5gxjNmcRD
- Les deux agents lisent leurs fichiers .md directement depuis le repo GitHub

**Connexions établies**
- GitHub App Claude installée sur le compte kamil911-stack / repo lexads-landing
- Notion MCP connecté (ee241b5d) — les agents écrivent dans Notion sans clé API locale

**Flow opérationnel**
- 8h : Hunter scrape avocat.fr + Google Maps, qualifie et enregistre dans Notion
- 9h : Emma lit les nouveaux prospects, rédige les brouillons, sauvegarde dans Notion et envoie un récap à kamilkhebbache911@gmail.com
- Kamil valide et déclenche l'envoi manuellement depuis Claude Code

**Premier run automatique** : 16/06/2026 à 8h02 Paris

---

## 2026-06-14

### Configuration agents, skills, SMTP et n8n-as-code

**Agents Perflux**
- 3 agents créés dans .claude/agents/ : Hunter (prospection), Emma (emails), Marcus (pilotage commercial)
- Skills intégrés directement dans les agents : BANT avocat, extraction email 3 passes, tiers prospecting, copywriting par étape (J0:150/J+3:80/J+7:120/J+14:100), personnalisation niveau 1-4, win/loss analysis, benchmarks performance

**Skills marketplace**
- Plugin Sales Skills installé : 100+ SKILL.md dans .agents/skills/ (outbound-prospecting, copywriting, email-sequence, ghost-recovery-sequences, etc.)
- Règles clés extraites et intégrées directement dans Hunter, Emma et Marcus

**Email et SMTP**
- Angle fiche Google My Business ajouté aux emails J0 Emma
- Lien Calendly intégré : https://calendly.com/kamil-perflux/30min
- SMTP IONOS opérationnel : smtp.ionos.fr port 465 SSL, kamil@perflux.fr
- MailKit installé (Send-MailMessage ne supporte pas port 465 implicit SSL)
- Credentials en variables d'env dans settings.json (jamais en dur)
- Test réussi : email reçu sur kamilkhebbache911@gmail.com

**n8n-as-code**
- Plugin n8n-as-code installé via marketplace Claude Code
- AGENTS.md et .github/agents/n8n-architect.agent.md auto-générés
- Permet de gérer les workflows n8n directement depuis Claude Code

---

## 2026-05-25

### Création du CRM de prospection Perflux
- CRM web app créée en HTML/CSS/JS (fichier : livrables/prospection/crm.html)
- 5 colonnes kanban : Nouveaux / Contactés / Intéressés / Rendez-vous / Lost
- Système de scoring sur 100 pts : Cabinet(10) + Dirigeant(25) + Téléphone(20) + Email(25) + Site web(10) + LinkedIn(10)
- Prospects Notion importés et pré-chargés dans le CRM avec scoring calculé
- Backup JSON créé : livrables/prospection/prospects-perflux.json

---

## 2026-05-23

### Mise en place routine prospection Perflux
- Routine automatique créée (claude.ai remote agent, ID : trig_012Yar1PELUh83u5YxyfZt69)
- Fréquence : tous les jours à 8h00 Paris
- Cible : avocats droit civil avec fiche Google My Business, Essonne (91) + Val-de-Marne (94)
- Quota : 50 prospects/jour (25 par département), ville par ville
- Données collectées : prénom/nom avocat, téléphone, email direct, ligne directe, site web, position Google, note GMB, présence Google Ads
- Résultats stockés dans base Notion "Prospects Perflux" (créée à la première exécution le 24/05)

### Lancement Perflux — Étude de marché + site vitrine
- Nom de l'agence choisi : Perflux
- Étude de marché complète rédigée (marché SEA France, portrait client avocat, concurrence, positionnement, offres, stratégie d'acquisition)
- Site vitrine créé et déployé sur Netlify (lexads.fr)
- Structure livrables organisée (prospection, offres, campagnes, clients, etc.)
- Prochaines étapes : certification Google Skillshop + lancement prospection

---

## 2026-05-21

### Installation initiale du Jarvis

- Workspace personnalisé pour Kamil, basé à Lisses (91), France
- Profil principal : Mix étudiant en alternance / account manager / entrepreneur en devenir
- Activité : Account manager chez Artur'in (300 comptes avocats et assureurs), étudiant B1 vente B2B haute technologie
- Objectifs court terme identifiés : lancer l'agence SEA à 3 000€ MRR, générer 2 000€ hors alternance en 2 mois, stopper addiction personnelle
- Vision long terme : agence en autonomie, liberté financière, installation définitive à Alger pour y développer un business
- Projets actifs au démarrage : création agence SEA, acquisition premiers clients, génération revenus rapides
- Domaine d'aide prioritaire : lancement et stratégie agence SEA, acquisition premiers clients
- Style de communication choisi : mélange selon contexte, vérité brute sans complaisance
