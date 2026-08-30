<div align = center>
  <a href="https://discord.gg/AYbJ9MJez7">
    <img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&suffix=%20members&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">
  </a>
</div>

###### _<div align="right"><a id=-design-by-t2></a><sub>// design by t2</sub></div>_

![hyde_banner](../assets/hyde_banner.png)

<!--
Multi-language README support
-->

[![es](https://img.shields.io/badge/lang-es-yellow.svg)](../docs/README.es.md)
[![de](https://img.shields.io/badge/lang-de-black.svg)](../docs/README.de.md)
[![nl](https://img.shields.io/badge/lang-nl-green.svg)](../docs/README.nl.md)
[![中文](https://img.shields.io/badge/lang-中文-orange.svg)](../docs/README.zh.md)
[![fr](https://img.shields.io/badge/lang-fr-blue.svg)](../docs/README.fr.md)
[![ar](https://img.shields.io/badge/lang-AR-orange.svg)](../docs/README.ar.md)
[![pt-br](https://img.shields.io/badge/lang-pt--br-006400.svg)](../docs/README.pt-br.md)
[![tr](https://img.shields.io/badge/lang-tr-e30a17.svg)](../docs/README.tr.md)

<div align="center">

<br>

<a href="#installation"><kbd> <br> Kurulum <br> </kbd></a>&ensp;&ensp;
<a href="#updating"><kbd> <br> Güncelleme <br> </kbd></a>&ensp;&ensp;
<a href="#themes"><kbd> <br> Temalar <br> </kbd></a>&ensp;&ensp;
<a href="#styles"><kbd> <br> Stiller <br> </kbd></a>&ensp;&ensp;
<a href="../../KEYBINDINGS.md"><kbd> <br> Tuş atamaları <br> </kbd></a>&ensp;&ensp;
<a href="https://www.youtube.com/watch?v=2rWqdKU1vu8&list=PLt8rU_ebLsc5yEHUVsAQTqokIBMtx3RFY&index=1"><kbd> <br> Youtube <br> </kbd></a>&ensp;&ensp;
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

Tam not için bu bağlantıya göz atın:
[HyDE ve ötesine yolculuk](../../Hyprdots-to-HyDE.md)

<!--
<img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&suffix=%20members&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">

<img alt="Dynamic JSON Badge" src="https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscordapp.com%2Fapi%2Finvites%2FmT5YqjaJFh%3Fwith_counts%3Dtrue&query=%24.approximate_presence_count&suffix=%20online&style=for-the-badge&logo=discord&logoSize=auto&label=The%20HyDe%20Project&labelColor=ebbcba&color=c79bf0">
-->

<https://github.com/prasanthrangan/hyprdots/assets/106020512/7f8fadc8-e293-4482-a851-e9c6464f5265>

<br>

<a id="installation"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=KURULUM" width="450"/>

---

Kurulum betiği (script), minimal [Arch Linux](https://wiki.archlinux.org/title/Arch_Linux) kurulumu için tasarlanmıştır, ancak **bazı** [Arch tabanlı dağıtımlarda](https://wiki.archlinux.org/title/Arch-based_distributions) da çalışabilir. HyDE'yi başka bir [DE](https://wiki.archlinux.org/title/Desktop_environment)/[WM](https://wiki.archlinux.org/title/Window_manager) ile birlikte kurmak mümkün olsa da, bu kurulumun büyük ölçüde özelleştirilmiş olması nedeniyle [GTK](https://wiki.archlinux.org/title/GTK)/[Qt](https://wiki.archlinux.org/title/Qt) temalarınız, [Shell](https://wiki.archlinux.org/title/Command-line_shell), [SDDM](https://wiki.archlinux.org/title/SDDM), [GRUB](https://wiki.archlinux.org/title/GRUB) vb. ile **çakışabilir** ve riski size aittir.

NixOS desteği için ayrı bir proje yürütülmektedir @ [Hydenix](https://github.com/richen604/hydenix/tree/main)

> [!IMPORTANT]
> Kurulum komut dosyası NVIDIA kartını otomatik olarak algılar ve çekirdeğiniz için nvidia-open-dkms sürücülerini yükler.
> Lütfen NVIDIA kartınızın sağlanan listede yer alan dkms sürücülerini desteklediğinden emin olun. [here](https://wiki.archlinux.org/title/NVIDIA).

> [!CAUTION]
> Bu komut dosyası, NVIDIA DRM'yi etkinleştirmek için `grub` veya `systemd-boot` yapılandırmanızı değiştirir.

Kurulum için aşağıdaki komutları çalıştırın:

```shell
pacman -S --needed git base-devel
git clone --depth 1 https://github.com/HyDE-Project/HyDE ~/HyDE
cd ~/HyDE/Scripts
./install.sh
```

> [!TIP]
> HyDE ile birlikte yüklemek istediğiniz diğer uygulamaları `Scripts/pkg_user.lst` dosyasına ekleyebilir ve dosyayı bir parametre olarak geçirerek şu şekilde yükleyebilirsiniz:
>
> ```shell
> ./install.sh pkg_user.lst
> ```

> [!IMPORTANT]
> `Scripts/pkg_extra.lst` dosyasındaki listenizi referans alın
> veya tüm ekstra paketleri yüklemek istiyorsanız `cp Scripts/pkg_extra.lst Scripts/pkg_user.lst` komutunu kullanabilirsiniz.

<!--

As a second install option, you can also use `Hyde-install`, which might be easier for some.
View installation instructions for HyDE in [Hyde-cli - Usage](https://github.com/kRHYME7/Hyde-cli?tab=readme-ov-file#usage).
-->

Kurulum betiği (script) tamamlandıktan ve sizi ilk kez SDDM oturum açma ekranına (veya siyah ekrana) yönlendirdikten sonra lütfen yeniden başlatın.
Daha fazla ayrıntı için lütfen [kurulum wiki](https://hydeproject.pages.dev/en/getting-started/installation) sayfasına bakın.

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="updating"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=GÜNCELLEME" width="450"/>

---

HyDE'yi güncellemek için GitHub'dan en son değişiklikleri almanız ve aşağıdaki komutları çalıştırarak yapılandırmaları geri yüklemeniz gerekir:

```shell
cd ~/HyDE/Scripts
git pull origin master
./install.sh -r
```

> [!IMPORTANT]
> `Scripts/restore_cfg.psv` dosyasında belirtildiği şekilde, yaptığınız tüm yapılandırmaların üzerine yazılacağını lütfen unutmayın.
> Ancak, değiştirilen tüm yapılandırmalar yedeklenir ve `~/.config/cfg_backups` dizininden geri yüklenebilir.

<!--
As a second update option, you can use `Hyde restore ...`, which does have a better way of managing restore and backup options.
For more details, you can refer to [Hyde-cli - dots management wiki](https://github.com/kRHYME7/Hyde-cli/wiki/Dots-Management).
-->

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="hydevm"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=HYDEVM" width="450"/>

---

HyDEVM, test ve geliştirme amacıyla HyDE'yi sanal makinede çalıştırmanıza olanak tanıyan bir komut dosyasıdır.

## Hızlı Başlangıç

### Arch Linux

```bash
# İndirin ve çalıştırın (eksik paketleri otomatik olarak algılar)
curl -L https://raw.githubusercontent.com/HyDE-Project/HyDE/main/Scripts/hydevm/hydevm.sh -o hydevm
chmod +x hydevm
./hydevm
```

### NixOS (veya Nix)

```bash
# HyDE deposundan flake kullanımı
nix run github:HyDE-Project/HyDE

# Veya depoyu yerel olarak klonladıysanız
nix run .
```

Daha fazla ayrıntı için lütfen [HyDEVM README](Scripts/hydevm/README.md) dosyasına bakın.

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="themes"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=TEMALAR" width="450"/>

---

Tüm resmi temalarımız ayrı bir depoda saklanır ve kullanıcılar bunları themepatcher ile yükleyebilir.
Daha fazla bilgi için [HyDE-Project/hyde-themes](https://github.com/HyDE-Project/hyde-themes) adresini ziyaret edin.

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
> Herkes, siz dahil, ek temalar oluşturabilir, sürdürebilir ve paylaşabilir; bunların hepsi themepatcher ile kurulabilir!
> Kendi özel temanızı oluşturmak için lütfen [theming wiki](https://github.com/prasanthrangan/hyprdots/wiki/Theming) sayfasına bakın.
> Hyde temanızın sergilenmesini istiyorsanız veya resmi olmayan temaları bulmak istiyorsanız [kRHYME7/hyde-gallery](https://github.com/kRHYME7/hyde-gallery) adresini ziyaret edin!

<div align="right">
  <br>
  <a href="#-design-by-t2"><kbd> <br> 🡅 <br> </kbd></a>
</div>

<a id="styles"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=STİLLER" width="450"/>

---

<div align="center"><table><tr>Tema Seçimi</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/theme_select_2.png"/></td></tr></table></div>

<div align="center"><table><tr><td>Duvar Kağıdı Seçimi</td><td>Başlatıcı Seçimi</td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/walls_select.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/rofi_style_sel.png"/></td></tr>
<tr><td>Wallbash Modları</td><td>Bildirim Eylemi</td></tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wb_mode_sel.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/notif_action_sel.png"/></td></tr>
</table></div>

<div align="center"><table><tr>Rofi Başlatıcısı</tr><tr><td>
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

<div align="center"><table><tr>Wlogout Menüsü</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/wlog_style_2.png"/></td></tr></table></div>

<div align="center"><table><tr>Oyun Başlatıcısı</tr><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_1.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_2.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_3.png"/></td></tr></table></div>
<div align="center"><table><tr><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_4.png"/></td><td>
<img src="https://raw.githubusercontent.com/prasanthrangan/hyprdots/main/Source/assets/game_launch_5.png"/></td></tr></table></div>



<a id="star_history"></a>
<img src="https://readme-typing-svg.herokuapp.com?font=Lexend+Giga&size=25&pause=1000&color=CCA9DD&vCenter=true&width=435&height=25&lines=YILDIZLAR" width="450"/>

---

<a href="https://star-history.com/#hyde-project/hyde&hyde-project/hyde-gallery&hyde-project/hyde-themes&Timeline">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=hyde-project/hyde&type=Timeline" />
 </picture>
</a>
