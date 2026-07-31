# Hi! 👋 Khing here

[![de](https://img.shields.io/badge/lang-de-black.svg)](Source/docs/Hyprdots-to-HyDE.de.md)
[![中文](https://img.shields.io/badge/lang-中文-orange.svg)](Source/docs/Hyprdots-to-HyDE.zh.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](Source/docs/Hyprdots-to-HyDE.es.md)

## This fork will enhance and fix prasanthrangan/hyprdots over time

### Why?

- Tittu (the original creator) is AFK for now, and I'm the only collaborator left. ⁉️
- My permissions are limited, so I can only merge PRs. If something breaks, I have to wait for help. 😭
- I won’t change everything in his dotfiles out of respect.
- This repo won't **overwrite** $USER's dotfiles.

**This fork is temporary and will bridge the old structure to a newer one [coming soon...].**

### Who are the $USER?

> **NOTE**: If you're confused why every `install.sh -r` overwrites your configs, you should fork [HyDE](https://github.com/HyDE-Project/HyDE), edit the `*.lst` file, and run the script. That’s the intended way.

Who are the $USER?

✅ Don’t want to maintain a fork
✅ Want to stay updated with this great dotfile
✅ Don’t know how the repo works
✅ Don’t have time to create your own dotfiles, just use this as inspiration
✅ Want a cleaner `~/.config` with everything structured like a real Linux package
✅ Demands a DE like experience

### ROADMAP 🛣️📍

- [ ] **Portable**

  - [ ] HyDE-specific files should be imported into $USER, not the other way around
  - [x] Keep it minimal
  - [ ] Make it packageable
  - [x] Follow XDG specs
  - [ ] Add Makefile

- [ ] **Extensible**

  - [ ] Add HyDE extension system
  - [ ] Predictable installation

- [ ] **Performance**

  - [ ] Optimize scripts for speed and efficiency
  - [ ] Make a single CLI to manage all the core script

- [ ] **Manageable**

  - [ ] Fix scripts (shellcheck compatible)
  - [x] Move scripts to `./lib/hyde`
  - [x] Make `wallbash*.sh` scripts monolithic, to fix wallbash issues

- [ ] **Better Abstraction**

  - [ ] Waybar
  - [x] Hyprlock
  - [x] Hyprsunset
  - [x] Animations
  - [ ] ...

- [ ] Clean up
- [ ] **...**

---

Here's how we keep HyDE's Hyprland settings separate from yours. HyDE's own
configuration lives in `~/.local/share/hypr/`, which it overwrites on every
update, and yours goes in `~/.config/hypr/hyprland.lua`, which loads after it
and is never touched. Anything else HyDE puts in `~/.config/hypr/` — the lock
screen, idle and sunset configs — is left alone once it exists. So an update
cannot overwrite your settings, and your settings cannot be lost with one.
Your own file is still yours to get wrong: a Lua error in it will stop the
session from starting, and a HyDE change may need a matching change there.

# Why name it HyDE?

As the last man standing collaborator, I don't know what the original creator intended. But I think it's a good name. I just don't know what it stands for. 🤷‍♂️

Here are the speculations from some of the contributors:

> - "**Hy**pr**D**otfiles **E**nhanced" - Enhanced version of hyprdots when @prasanthrangan introduced wallbash as our main theme management engine.

> - But the one that makes the most sense is - "**Hy**prland **D**esktop **E**nvironment" - as Hyprland is usually considered a WM for Wayland, not a full-fledged D.E. and this dotfile kind of turns it into a full-blown D.E.
>   -chrollorifat

> - "HyDE, your Development Environment" - khing

**Feel free to suggest your own meaning of HyDE. 🤔**
