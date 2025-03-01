# Directives pour les Messages de Commit
<!--
Support multi-langue pour COMMIT_MESSAGE_GUIDELINES
-->

[![en](https://img.shields.io/badge/lang-en-red.svg)](../../COMMIT_MESSAGE_GUIDELINES.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](COMMIT_MESSAGE_GUIDELINES.es.md)
[![de](https://img.shields.io/badge/lang-de-black.svg)](COMMIT_MESSAGE_GUIDELINES.de.md)

Un bon message de commit doit être descriptif et fournir du contexte sur les modifications apportées. Cela facilite la compréhension et la révision des changements à l’avenir.

Voici quelques directives pour rédiger des messages de commit clairs et descriptifs :

- Commencez par un résumé court des modifications apportées dans le commit.
- Utilisez l'impératif dans le résumé, comme si vous donniez un ordre. Par exemple, "Ajoute une fonctionnalité" au lieu de "Ajouté une fonctionnalité".
- Ajoutez des détails supplémentaires dans le corps du message si nécessaire. Cela peut inclure la raison du changement, son impact ou toute dépendance ajoutée ou supprimée.
- Limitez la longueur des lignes à 72 caractères afin d’assurer une bonne lisibilité dans l’historique Git.

Exemples de bons messages de commit

- "Ajoute une fonctionnalité d’authentification pour la connexion utilisateur"
- "Corrige un bug provoquant un crash de l’application au démarrage"
- "Met à jour la documentation des points d’API"

Rédiger des messages de commit descriptifs permet de gagner du temps et d'éviter la frustration à l'avenir en aidant les autres à comprendre les modifications apportées au code.

## Types de Messages de Commit

Voici une liste plus complète des types de commit que vous pouvez utiliser :

### `feat` : Ajout d’une nouvelle fonctionnalité au projet

```markdown
feat: ajout le support de téléchargement multi-images
```

`fix`: Correction d’un bug ou d’un problème dans le projet

```markdown
fix: Corrige un bug provoquant un crash de l’application au démarrage
```

`docs`: Mise à jour de la documentation du projet

```markdown
docs: Met à jour la documentation des points d’API
```

`style`: Modifications cosmétiques ou de style dans le projet (comme changer les couleurs ou formater le code)

```markdown
style: Met à jour les couleurs et le formatage
```

`refactor`: Modifications du code qui n’affectent pas le comportement du projet, mais améliorent sa qualité ou sa maintenabilité

```markdown
refactor: Supprime le code inutilisé
```

`test`: Ajout ou modification de tests pour le projet

```markdown
test: Ajoute des tests pour une nouvelle fonctionnalité
```

`chore`: Modifications du projet qui ne rentrent dans aucune autre catégorie, comme la mise à jour des dépendances ou la configuration du système de build

```markdown
chore: Met à jour les dépendances
```

`perf`: Amélioration des performances du projet

```markdown
perf: Améliore les performances du traitement des images
```

`security`: Résolution des problèmes de sécurité dans le projet

```markdown
security: Met à jour les dépendances pour résoudre des problèmes de sécurité
```

`merge`: Fusion de branches dans le projet

```markdown
merge: Fusionne la branche 'feature/branch-name' dans develop
```

`revert`: Annulation d'un commit précédent

```markdown
revert: revert: Annule "Ajoute une fonctionnalité"
```

`build`: Modifications du système de build ou des dépendances du projet

```markdown
build: build: Met à jour les dépendances
```

`ci`: Modifications du système d’intégration continue (CI) pour le projet

```markdown
ci: Met à jour la configuration CI
```

`config`: Modifications des fichiers de configuration du projet

```markdown
config: Met à jour les fichiers de configuration
```

`deploy`: Met à jour les scripts de déploiement

```markdown
deploy: Met à jour les scripts de déploiement

```

`init`: Création ou initialisation d’un nouveau dépôt ou projet

```markdown
init: Initialise le projet

```

`move`: Déplacement de fichiers ou de répertoires dans le projet

```markdown
move: Déplace les fichiers vers un nouveau répertoire
```

`rename`: Renommage de fichiers ou de répertoires dans le projet

```markdown
rename: Renommage de fichiers
```

`remove`: Suppression de fichiers ou de répertoires du projet

```markdown
remove: Suppression de fichiers
```

`update`: Mise à jour du code, des dépendances ou d’autres composants du projet

```markdown
update: Met à jour le code. 
```

Ce ne sont que quelques exemples, et vous pouvez également créer vos propres types de commit personnalisés. Cependant, il est important de les utiliser de manière cohérente et de rédiger des messages de commit clairs et descriptifs pour faciliter la compréhension des modifications apportées par les autres.

**Important :** Si vous prévoyez d’utiliser un type de message de commit personnalisé autre que ceux listés ci-dessus, assurez-vous de l’ajouter à cette liste afin que les autres puissent également le comprendre. Créez une pull request pour l’ajouter à ce fichier.