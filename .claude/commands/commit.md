# /commit

> Commande pour sauvegarder le workspace avec Git.

---

## Mission

Quand je lance `/commit`, exécute la séquence suivante :

### Étape 1 : Initialiser Git si besoin

Vérifie si un dépôt Git existe déjà (`git status`). Si ce n'est pas le cas, initialise avec `git init`.

### Étape 2 : Vérifier l'état

Lance `git status` pour voir ce qui a changé depuis le dernier commit.

Affiche-moi un résumé lisible de ce qui va être sauvegardé (fichiers modifiés, ajoutés, supprimés).

### Étape 3 : Générer un message de commit

Analyse les changements et génère un message de commit clair en français, au format :

```
type: résumé court des changements

- détail 1
- détail 2
```

Types possibles : `ajout`, `modif`, `suppression`, `structure`, `config`

### Étape 4 : Demander confirmation

Présente-moi le message de commit proposé et demande :

> "Je vais sauvegarder avec ce message. Tu confirmes ?"

### Étape 5 : Committer

Une fois confirmé :
1. `git add .`
2. `git commit -m "[message]"`

Confirme que la sauvegarde est bien effectuée.

---

## Règles

- Ne jamais committer sans ma confirmation explicite
- Si c'est le premier commit, le signaler et expliquer ce que ça fait
- Message de commit toujours en français
- Pas de `--no-verify`
