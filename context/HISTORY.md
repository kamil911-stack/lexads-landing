# Workspace History

> Journal chronologique de toutes les sessions et décisions importantes.
> Le plus récent en haut. Mis à jour automatiquement par Claude.
>
> **Comment ça marche :** Quand je lance la commande `/update` après une session importante, ou quand je raconte un changement significatif, Claude ajoute une entrée ici automatiquement. Je n'ai pas à écrire ce fichier manuellement.

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
