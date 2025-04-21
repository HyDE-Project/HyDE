# 嗨! 👋 这里是 Khing

[![de](https://img.shields.io/badge/lang-de-black.svg)](./Hyprdots-to-HyDE.de.md)
[![en](https://img.shields.io/badge/lang-en-red.svg)](../../Hyprdots-to-HyDE.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](./Hyprdots-to-HyDE.es.md)

## 这个分支项目会逐渐修复 prasanthrangan/hyprdots 项目中的漏洞，并不断优化

### 为什么要这么做?

- Tittu (最初的项目创建者) 目前少有贡献了, 并且我似乎是所剩唯一的协作者. ⁉️
- 我的权限十分受限, 我只能合并PR. 如果代码出了问题, 我就无能为力了. 😭
- 出于尊重，我不会对他的配置文件(点文件)做任何修改。
- 这个仓库不会**覆盖** '$USER' 的配置文件.

**这个分支是暂时的，我们[未来]会把旧的部分桥接到新的架构上。**

### $USER 是谁?

> **注意**: 如果你奇怪为什么每次 ```install.sh -r``` 都会覆盖您的配置，您应该 fork [HyDE](https://github.com/HyDE-Project/HyDE)，编辑 ```*.lst``` 文件。这才是我们预期的方式。

所以 $USER 是谁？他们：

✅ 不想维护一个 fork
✅ 想要保持更新最新和最好的配置文件(点文件)
✅ 不清楚这个仓库是怎样运行的
✅ 没时间创建自己的配置文件，仅将这个仓库作为基础模板来魔改。
✅ 想要一个干净而结构清晰的 ```~/.config``` 目录，像一个真正的 Linux 包一样。
✅ 需要一个像桌面环境一样的一站式体验。

### 规划 🛣️📍

- [ ] **可移植**

  - [ ] HyDE-相关文件应该导入 \$USER，而不是相反。
  - [X] 保持项目轻便简洁
  - [ ] 使其易于打包
  - [X] 依照 XDG 文档
  - [ ] 添加 Makefile

- [ ] **可扩展**

  - [ ] 添加 HyDE 插件系统
  - [ ] 安装可预测

- [ ] **性能**

  - [ ] 优化脚本速度和效率
  - [ ] 编写统一的脚本文件来管理所有核心脚本

- [ ] **易于管理**
  - [ ] 修复已有脚本(shellcheck 兼容)
  - [X] 移动脚本到`./lib/hyde`
  - [X] 统一 `wallbash*.sh` 脚本到一个脚本, 修复 wallbash 的问题。
- [ ] **电源管理抽象**
  - [ ] Waybar
  - [x] Hyprlock
  - [x] 动画
  - [ ] ...
- [ ] 清理
- [ ] **...**

---

接下来我们要谈谈如何在不改变用户配置的情况下更新 HyDE 相关的配置文件。
我们不再需要 “userprefs” 文件。相对的，我们可以引用(source) HyDE 的 hyprland.conf 并允许\$USER 直接在配置中更改。通过这个方式，您不会破坏 hyde，hyde 也不会破坏您的配置文件。

![Hyprland structure](https://github.com/user-attachments/assets/91b35c2e-0003-458f-ab58-18fc29541268)

# 为什么叫 HyDE?

作为最后一个活跃维护者，我不太清楚为什么最初的创建者的用意。但我觉得这是个不错的名字。我只是不知道为什么这么叫。🤷‍♂️

以下是我的一些猜测：

- **Hy**prdots **D**otfiles **E**nhanced - 即Hyprdots的加强版本，它使用 @prasanthrangan 引入的 wallbash 作为主要的主题引擎。
- **Hy**prland **D**otfiles **E**xtended - 即Hypeland的可扩展配置文件集。
- 但最有可能的是 - **Hy**prland **D**esktop **E**nvironment - 由于 Hyprland 通常被看作是一个 wayland 窗口管理器(WM)，而不是一个成熟的桌面管理器(DE)，这个配置文件集在某种程度省将其变为了一个成熟的桌面管理器。

请随意提出你自己对 HyDE 的理解。🤔
