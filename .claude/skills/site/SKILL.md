---
name: site
description: Conception et optimisation de sites web — design frontend distinctif + audit SEO. À utiliser quand Kamil travaille sur le site Perflux ou sur les sites de clients, pour allier identité visuelle forte et référencement efficace.
---

# Site — Design Frontend + SEO

Ce skill combine deux expertises complémentaires : créer une identité visuelle qui ne ressemble à personne d'autre, et s'assurer que les moteurs de recherche (et l'IA) la trouvent et la citent.

---

## Partie 1 — Design Frontend

Approche ce travail comme le directeur artistique d'un petit studio réputé pour donner à chaque client une identité visuelle impossible à confondre avec une autre. Ce client a déjà refusé des propositions qui sentaient le template : fais des choix délibérés et opinionés sur la palette, la typographie et le layout, spécifiques à ce brief, et prends un risque esthétique que tu peux justifier.

### Ancre-toi dans le sujet

Si le brief ne précise pas ce qu'est le produit, précise-le toi-même avant de concevoir : nomme un sujet concret, son audience, et l'unique objectif de la page. L'univers propre au sujet — ses matériaux, ses instruments, ses artefacts, son langage — est la source des choix distinctifs. Construis avec le vrai contenu du brief tout au long du travail.

### Principes de design

**Le hero est une thèse.** Ouvre avec la chose la plus caractéristique de l'univers du sujet, sous quelque forme que ce soit : un titre, une image, une animation, une démo live. Un grand nombre avec un petit label, des stats d'appui et un accent en dégradé, c'est la réponse template. Ne l'utilise que si c'est vraiment la meilleure option.

**La typographie porte la personnalité de la page.** Associe les fontes display et corps délibérément, pas les mêmes familles que tu choisirais pour n'importe quel autre projet. Établis une échelle typographique claire avec des graisses, chasses et espacements intentionnels. Rends le traitement typographique lui-même mémorable, pas un simple vecteur neutre de contenu.

**La structure est de l'information.** Les dispositifs structurels — numérotation, eyebrows, séparateurs, labels — doivent encoder quelque chose de vrai sur le contenu, pas le décorer. Les marqueurs numérotés (01 / 02 / 03) ne sont appropriés que si le contenu est une vraie séquence. Questionne chaque choix de ce type.

**Anime délibérément.** Réfléchis à où et si l'animation sert le sujet : une séquence au chargement, un déclenchement au scroll, des micro-interactions au survol, une atmosphère ambiante. Un moment orchestré frappe souvent plus fort que des effets éparpillés. Parfois moins c'est plus.

**Correspond la complexité à la vision.** Une direction maximaliste nécessite une exécution élaborée ; une direction minimaliste exige une précision dans l'espacement, la typographie et le détail. L'élégance, c'est bien exécuter la vision choisie.

### Processus : brainstorm → plan → critique → build → critique

Les designs AI se regroupent souvent autour de trois looks : (1) fond crème chaud avec serif haute contrast et accent terracotta ; (2) fond quasi-noir avec accent acide vert ou vermillon ; (3) layout broadsheet avec règles fines et colonnes denses. Les trois sont légitimes pour certains briefs, mais ce sont des défauts plutôt que des choix. Si le brief fixe une direction visuelle, suis-la exactement. Si un axe est libre, ne dépense pas cette liberté sur un de ces défauts.

Travaille en deux passes. D'abord, brainstorme un plan design compact :
- **Couleur** : décris la palette en 4 à 6 valeurs hex nommées
- **Typographie** : les fontes pour 2+ rôles (une fonte display caractérisée + une fonte corps complémentaire)
- **Layout** : concept de layout en maquette ASCII
- **Signature** : l'unique élément dont cette page sera mémorable

Puis critique ce plan avant de coder : si une partie ressemble au default générique, révise-la, dis ce que tu as changé et pourquoi. Code seulement après confirmation que le plan est suffisamment distinctif.

### Retenue et autocritique

Dépense ta hardiesse en un seul endroit. Laisse l'élément signature être la seule chose mémorable, garde tout le reste calme et discipliné, et coupe toute décoration qui ne sert pas le brief. Critique ton propre travail au fur et à mesure. Responsive mobile, focus clavier visible, reduced motion respecté.

---

## Partie 2 — SEO

Après (ou en parallèle du) design, le SEO s'assure que le site est trouvé, compris et cité — par Google et par les IA génératives.

### Quand utiliser les skills SEO

Les skills SEO globaux sont installés dans `~/.claude/skills/seo*/`. Tu peux les déclencher directement :

```
/seo audit https://perflux.fr        → audit complet (10-15 min, 18 agents parallèles)
/seo page https://perflux.fr         → analyse on-page profonde
/seo schema https://perflux.fr       → vérification + génération schema.org
/seo local https://perflux.fr        → SEO local (GBP, citations, avis)
/seo geo https://perflux.fr          → optimisation pour les AI Overviews Google
```

### Priorités SEO pour Perflux

1. **Schema LocalBusiness + LegalService** : les avocats ont des données structurées spécifiques. Génère un JSON-LD complet avec `areaServed`, `serviceType`, `geo`.
2. **GEO (AI Overviews)** : Google cite de plus en plus les agences SEA dans ses overviews si le contenu est passage-citeable. Optimise les sections de témoignages et de résultats.
3. **SEO local** : si le client cible une zone géographique spécifique, la page doit inclure un signalement géographique clair dans les métadonnées et le schema.
4. **Core Web Vitals** : LCP < 2,5s, CLS < 0,1, INP < 200ms. À vérifier après chaque refonte design.

### Utilisation pour prospecter

Avant de contacter un cabinet, audite rapidement leur site avec `/seo page <url>` pour identifier 2-3 failles concrètes à mentionner dans l'email Emma. C'est la personnalisation niveau 3-4 : pas "vous n'êtes pas visible", mais "votre page de contact n'a pas de schema Review alors que vos 3 concurrents directs sur 'avocat Évry' en ont un."

---

## Principe d'ensemble

Design distinctif + SEO solide = un site qui frappe visuellement ET qui est trouvé. Ne pas optimiser l'un au détriment de l'autre. Un beau site invisible ne convertit pas. Un site bien référencé mais générique ne convainc pas.
