# From HyDE to DOORwayDE

## Why This Fork Exists

DOORwayDE is the Hyprland Desktop Environment for [HALLway OS](https://github.com/MarkusBitterman/HALLway). It started as a fork of [HyDE](https://github.com/HyDE-Project/HyDE), which itself evolved from [prasanthrangan's hyprdots](https://github.com/prasanthrangan/hyprdots).

Rather than build a Hyprland configuration from scratch, I chose HyDE as the foundation because it had already solved the hard problems:

- Mature theme engine (wallbash)
- Polished Waybar, rofi, and dunst integration
- Extensive keybinding framework
- Active community battle-testing

The goal was never to diverge from HyDE for its own sake, but to adapt it for a specific purpose: running on NixOS as part of the HALLway ecosystem.

## The Migration Story

This project represents a personal migration from rolling Arch-style Linux to declarative NixOS.

**The old way:**
- Install scripts that imperatively modify system state
- Dotfiles scattered across `~/.config` with manual symlinks
- "It works on my machine" configuration drift
- Reinstalls mean re-running setup scripts and hoping nothing broke

**The HALLway way:**
- Nix flake with Home Manager module
- Configs live in the repo, symlinked declaratively
- Reproducible builds — the same flake.lock produces the same system
- Fork-friendly — clone, modify, deploy

DOORwayDE bridges HyDE's Arch-centric install scripts with NixOS's declarative approach. The bash scripts still exist for quick testing, but the real deployment path is through the Nix flake.

## The Naming Journey

The project went through several names:

### HyDE → HALLwayDE
First attempt. The idea was "HyDE for HALLway OS." But this created confusion — is HALLwayDE part of HALLway, or is it the whole thing? The names were too similar.

### HALLwayDE → DOORwayDE
The HALLway Project Bible describes the core metaphor:

> *"Build your home setup like a well-lit hallway with doors, not a haunted house of mystery devices and broken Windows."*

DOORwayDE is the **door** to your HALLway — the graphical entry point where you interact with your declarative, secure-by-default system. The name fits the metaphor and distinguishes the desktop environment from the OS itself.

## What DOORwayDE Is (and Isn't)

**DOORwayDE IS:**
- A Hyprland desktop environment optimized for NixOS
- Part of the HALLway ecosystem
- Its own project with its own identity
- Fork-friendly — designed to be cloned and customized

**DOORwayDE is NOT:**
- "A port of HyDE" — it shares lineage but has its own direction
- A general-purpose dotfiles repo — it serves HALLway specifically
- Trying to replace HyDE — use HyDE on Arch, use DOORwayDE on HALLway/NixOS

## Upstream Relationship

DOORwayDE gratefully acknowledges its upstream lineage:

- [HyDE](https://github.com/HyDE-Project/HyDE) — The Hyprland Desktop Environment by kRHYME7 and contributors
- [hyprdots](https://github.com/prasanthrangan/hyprdots) — The original dotfiles by prasanthrangan

Theme files and wallbash templates retain upstream attribution. When merging upstream changes, HyDE references are preserved where appropriate for credit.

---

*Built for HALLway OS. Forked from HyDE. Designed for calm, declarative computing.*
