<div align="center">
  <a href="https://discord.gg/AYbJ9MJez7">
    <img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&suffix=%20membres&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">
  </a>
</div>

###### _<div align="right"><a id=-design-by-t2></a><sub>// design par t2</sub></div>_

![hyde_banner](../assets/hyde_banner.png)

<!--
Support multilingue pour le README
-->

[![en](https://img.shields.io/badge/lang-en-red.svg)](../../README.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](README.es.md)
[![de](https://img.shields.io/badge/lang-de-black.svg)](README.de.md)
[![nl](https://img.shields.io/badge/lang-nl-green.svg)](README.nl.md)
[![中文](https://img.shields.io/badge/lang-中文-orange.svg)](README.zh.md)
[![ar](https://img.shields.io/badge/lang-AR-orange.svg)](README.ar.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-006400.svg)](README.pt-br.md)

<div align="center">

<br>

<a href="#installation"><kbd> <br> Installation <br> </kbd></a>&ensp;&ensp;
<a href="#update"><kbd> <br> Mise à jour <br> </kbd></a>&ensp;&ensp;
<a href="#themes"><kbd> <br> Thèmes <br> </kbd></a>&ensp;&ensp;
<a href="#styles"><kbd> <br> Styles <br> </kbd></a>&ensp;&ensp;
<a href="KEYBINDINGS.fr.md"><kbd> <br> Raccourcis <br> </kbd></a>&ensp;&ensp;
<a href="https://www.youtube.com/watch?v=2rWqdKU1vu8&list=PLt8rU_ebLsc5yEHUVsAQTqokIBMtx3RFY&index=1"><kbd> <br> YouTube <br> </kbd></a>&ensp;&ensp;
<a href="https://hydeproject.pages.dev/"><kbd> <br> Wiki <br> </kbd></a>&ensp;&ensp;
<a href="https://discord.gg/qWehcFJxPa"><kbd> <br> Discord <br> </kbd></a>

</div><br><br>

<div align="center">
  <div style="display: flex; flex-wrap: nowrap; justify-content: center;">
    <img src="../assets/archlinux.png" alt="Arch Linux" style="width: 10%; margin: 10px;"/>
    <img src="../assets/cachyos.png" alt="CachyOS" style="width: 10%; margin: 10px;"/>
    <img src="../assets/endeavouros.png" alt="EndeavourOS" style="width: 10%; margin: 10px;"/>
    <img src="../assets/garuda.png" alt="Garuda" style="width: 10%; margin: 10px;"/>
    <img src="../assets/nixos.png" alt="NixOS" style="width: 10%; margin: 10px;"/>
  </div>
</div>

Consultez ceci pour voir la note complète :
[Voyage vers HyDE et au-delà](../../Hyprdots-to-HyDE.md)

<!--
<img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&suffix=%20members&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">

<img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_presence_count&suffix=%20online&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">
-->

<https://github.com/prasanthrangan/hyprdots/assets/106020512/7f8fadc8-e293-4482-a851-e9c6464f5265>

<br>

<a id="installation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=INSTALLATION" width="450"/>

---

Le script d'installation est conçu pour une installation minimale d'[Arch Linux](https://wiki.archlinux.org/title/Arch_Linux), mais **peut** fonctionner sur certaines [distributions basées sur Arch](https://wiki.archlinux.org/title/Arch-based_distributions). Lors de l'installation de HyDE avec un autre [DE](https://wiki.archlinux.org/title/Desktop_environment)/[WM](https://wiki.archlinux.org/title/Window_manager), cela devrait fonctionner, mais en raison de sa configuration très personnalisée, **il y aura** des conflits avec votre thème [GTK](https://wiki.archlinux.org/title/GTK)/[Qt](https://wiki.archlinux.org/title/Qt), [Shell](https://wiki.archlinux.org/title/Command-line_shell), [SDDM](https://wiki.archlinux.org/title/SDDM), [GRUB](https://wiki.archlinux.org/title/GRUB), etc., et c'est à vos risques et périls.

Pour supporter NixOS, un projet séparé est maintenu @ [Hydenix](https://github.com/richen604/hydenix/tree/main)

> [!IMPORTANT]
> Le script d'installation détectera automatiquement une carte NVIDIA et installera les pilotes nvidia-dkms pour votre noyau.
> Assurez-vous que votre carte NVIDIA supporte les pilotes dkms dans la liste fournie [ici](https://wiki.archlinux.org/title/NVIDIA).

> [!CAUTION]
> Le script modifie votre configuration `grub` ou `systemd-boot` pour activer NVIDIA DRM.

Pour installer, exécutez les commandes suivantes :

```shell
pacman -S --needed git base-devel
git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts
./install.sh
```

> [!TIP]
> Vous pouvez également ajouter toutes les applications que vous souhaitez installer aux côtés de HyDE dans `Scripts/pkg_user.lst` et passer le fichier en paramètre pour l'installer ainsi :
>
> ```shell
> ./install.sh pkg_user.lst
> ```

> [!IMPORTANT]
> Consultez votre liste dans `Scripts/pkg_extra.lst`
> ou vous pouvez `cp  Scripts/pkg_extra.lst Scripts/pkg_user.lst` si vous souhaitez installer tous les paquets supplémentaires.

<!--
Comme deuxième option d'installation, vous pouvez aussi utiliser `Hyde-install`, ce qui peut être plus simple pour certains.
Voir les instructions d'installation pour HyDE dans [Hyde-cli - Usage](https://github.com/kRHYME7/Hyde-cli?tab=readme-ov-file#usage).
-->

Veuillez redémarrer après que le script d'installation se termine et vous amène à l'écran de connexion SDDM (ou écran noir) pour la première fois.
Pour plus de détails, veuillez consulter le [wiki d'installation](https://github.com/HyDE-Project/HyDE/wiki/installation).

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="updating"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=MISE%20À%20JOUR" width="450"/>

---

Pour mettre à jour HyDE, vous devrez tirer les dernières modifications de GitHub et restaurer les configurations en exécutant les commandes suivantes :

```shell
cd ~/HyDE/Scripts
git pull origin master
./install.sh -r
```

> [!IMPORTANT]
> Veuillez noter que toute configuration que vous avez effectuée sera écrasée si elle est listée pour l'être comme indiqué par `Scripts/restore_cfg.psv`.
> Cependant, toutes les configurations remplacées sont sauvegardées et peuvent être récupérées depuis `~/.config/cfg_backups`.

<!--
En tant qu'option de mise à jour secondaire, vous pouvez utiliser `Hyde restore ...`, qui offre une meilleure gestion des options de restauration et de sauvegarde.
Pour plus de détails, vous pouvez consulter [Hyde-cli - wiki sur la gestion des points](https://github.com/kRHYME7/Hyde-cli/wiki/Dots-Management).
-->

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="themes"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=THEMES" width="450"/>

---

Tous nos thèmes officiels sont stockés dans un dépôt séparé, permettant aux utilisateurs de les installer à l'aide de `themepatcher`.
Pour plus d'informations, visitez [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes).

<div align="center">
  <table><tr><td>

[![Catppuccin-Latte](https://placehold.co/130x30/dd7878/eff1f5?text=Catppuccin-Latte&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Catppuccin-Latte)
[![Catppuccin-Mocha](https://placehold.co/130x30/b4befe/11111b?text=Catppuccin-Mocha&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Catppuccin-Mocha)
[![Decay-Green](https://placehold.co/130x30/90ceaa/151720?text=Decay-Green&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Decay-Green)
[![Edge-Runner](https://placehold.co/130x30/fada16/000000?text=Edge-Runner&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Edge-Runner)
[![Frosted-Glass](https://placehold.co/130x30/7ed6ff/1e4c84?text=Frosted-Glass&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Frosted-Glass)
[![Graphite-Mono](https://placehold.co/130x30/a6a6a6/262626?text=Graphite-Mono&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Graphite-Mono)
[![Gruvbox-Retro](https://placehold.co/130x30/475437/B5CC97?text=Gruvbox-Retro&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Gruvbox-Retro)
[![Material-Sakura](https://placehold.co/130x30/f2e9e1/b4637a?text=Material-Sakura&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Material-Sakura)
[![Nordic-Blue](https://placehold.co/130x30/D9D9D9/476A84?text=Nordic-Blue&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Nordic-Blue)
[![Rosé-Pine](https://placehold.co/130x30/c4a7e7/191724?text=Rosé-Pine&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Rose-Pine)
[![Synth-Wave](https://placehold.co/130x30/495495/ff7edb?text=Synth-Wave&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Synth-Wave)
[![Tokyo-Night](https://placehold.co/130x30/7aa2f7/24283b?text=Tokyo-Night&font=Oswald)](https://github.com/HyDE-Project/hyde-themes/tree/Tokyo-Night)

  </td></tr></table>
</div>

> [!TIP]
> Chacun, y compris vous, peut créer, maintenir et partager des thèmes supplémentaires, tous installables via themepatcher !
> Pour créer votre propre thème personnalisé, veuillez consulter le [wiki des thèmes](https://github.com/prasanthrangan/hyprdots/wiki/Theming).
> Si vous souhaitez que votre thème hyde soit mis en avant ou si vous voulez trouver des thèmes non officiels, visitez [kRHYME7/hyde-gallery](https://github.com/kRHYME7/hyde-gallery) !

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="styles"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=STYLES" width="450"/>

---

<div align="center"><table><tr>Sélection de thème</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_2.png"/></td></tr></table></div>

<div align="center"><table><tr><td>Sélection de fond d'écran</td><td>Sélection de lanceur</td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/walls_select.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_sel.png"/></td></tr>
<tr><td>Modes Wallbash</td><td>Action de notification</td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wb_mode_sel.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/notif_action_sel.png"/></td></tr>
</table></div>

<div align="center"><table><tr>Lanceur Rofi</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_2.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_3.png"/></td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_4.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_5.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_6.png"/></td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_7.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_8.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_9.png"/></td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_10.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_11.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_12.png"/></td></tr>
</table></div>

<div align="center"><table><tr>Menu Wlogout</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_2.png"/></td></tr></table></div>

<div align="center"><table><tr>Lanceur de jeu</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_2.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_3.png"/></td></tr></table></div>
<div align="center"><table><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_4.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_5.png"/></td></tr></table></div>

<!--
<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<div align="center">

</div>
-->

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<div align="right">
  <sub>Dernière modification : 21/03/2025<span id="last-edited"></span></sub>
</div>

<a id="star_history"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=STARS" width="450"/>

---

<a href="https://star-history.com/#hyde-project/hyde&hyde-project/hyde-gallery&hyde-project/hyde-themes&Timeline">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline" />
 </picture>
</a>
