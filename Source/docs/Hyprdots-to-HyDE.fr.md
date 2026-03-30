# Bonjour ! 👋 C'est Khing qui vous parle

[![de](https://img.shields.io/badge/lang-de-black.svg)](./Hyprdots-to-HyDE.de.md)
[![中文](https://img.shields.io/badge/lang-中文-orange.svg)](./Hyprdots-to-HyDE.zh.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](./Hyprdots-to-HyDE.es.md)
[![en](https://img.shields.io/badge/lang-en-blue.svg)](../../Hyprdots-to-HyDE.md)

## Ce fork va améliorer et réparer prasanthrangan/hyprdots au fil des années (et des mise à jours) 

### Pourquoi ?

- Tittu (le créateur original (le premier quoi)) est AFK pour l'instant, et je suis le seul contributeur restant. ⁉️
- Mes permissions sont limitées, donc je peux seulement merge les PRs*. Si il quelque chose se casse, je doit attendre de l'aide. 😭
- Par respect, ne changerai pas tous* dans les dotfiles.
- Ce repo ne va pas **remplacer** les dotfiles du $USER.

**Ce fork est temporaire et va passer ce l'ancienne structure à une nouvelle [Arrive bientôt...].**

### Qui est $USER?

> **NOTE**: Si vous êtes confus avec le fichier `install.sh -r` sur le fait qu'il remplace vos configs, vous devriez fork [HyDE](https://github.com/HyDE-Project/HyDE), editer le fichier `*.lst`, et lancer le script. C'est le fonctionnement prévu.

Qui est $USER?

✅ Ne veux pas maintenir un fork
✅ Veux rester à jour avec cet SUPER config
✅ Ne sais pas comment les repo fonctionnent
✅ Vous n'avez pas le temps de créer vos propres fichiers de configuration ? Utilisez ceci comme source d'inspiration.
✅ Veux un `~/.config` propre avec tout structuré comme un vrai packet linux 
✅ Demande une expérience qui ressemble à celle d'un DE ( Environnement de Bureau)

### ROADMAP 🛣️📍

- [ ] **Portable**

  - [ ] Les fichiers spécifique à HyDE devraient être importé dans $USER, pas d'autre chemin autour
  - [x] Garder miniature
  - [ ] Faire en sorte qu'il soit empaquetable
  - [x] Garde les specs XDG
  - [ ] Ajouter un fichier Makefile

- [ ] **Extensible** *

  - [ ] Ajouter un système d'extension pour HyDE
  - [ ] Une installation predisable*

- [ ] **Performant**

  - [ ] Optimiser les scripts pour qu'il soient rapides et efficaces
  - [ ] Faire une seul CLI (client) pour tous les scripts du noyau

- [ ] **Gérable**

  - [ ] Réparer les scripts (compatble shellcheck)
  - [x] Bouger les script vers `./lib/hyde`
  - [x] Faire du script `wallbash*.sh` monolithic*, pour réparer les bugs*

- [ ] **Meilleur abstraction**

  - [ ] Waybar
  - [x] Hyprlock
  - [x] Animations
  - [ ] ...

- [ ] Netoyer
- [ ] **...**

---

Comment mettre à jour les parmètres de Hyprland spécifique à HyDE sans changer les préférences de l'utilisateur. Nous n'avons pas besoin du fichier "userprefs".  À la place, nous faisons le fichier `hyprland.conf` de HyDE et faisons les changement préféré de $USER directement dans les configs. Avec cet approche, vous n'allez pas potentiellement cassez HyDE et HyDE ne vas pas casser vos dots.

![La structure d'hyprland](https://github.com/user-attachments/assets/91b35c2e-0003-458f-ab58-18fc29541268)

# Pourquoi HyDE comme nom ?

Comme étant le dernier contributeur restant, Je ne sais pas à quoi penssait le créateur original. Mais je pense que c'est un super nom. Je ne sais juste pas ce que cela signifie. 🤷‍♂️

Certain contributeur penssent que:

> - "**Hy**pr**D**otfiles **E**nhanced" - Une version amélioré de hyprdots quand @prasanthrangan à sorti wallbash qui est notre principal moteur de theme. *

> - Mais celui qui à le plus de sens est  - "**Hy**prland **D**esktop **E**nvironment" - comme Hyprland est souvent considéré comme étant une WM pour Wayland, pas un DE à part et ces dotfiles en font un DE à part entière.
> - chlorofat *

> - "HyDE, environnement de développement" - khing

**Sentez vous libre de suggerer votre sens * de HyDE. 🤔**
