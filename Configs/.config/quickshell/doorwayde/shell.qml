//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// DOORwayDE QuickShell — forked from end-4/dots-hyprland (GPLv3)
// Phase 12: top bar only. Sidebars, OSD, notifications follow in Phases 13-15.

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

ShellRoot {
    id: root

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
    }

    // Phase 12: bar only. IllogicalImpulseFamily is bar-only until Phase 13.
    Loader {
        active: Config.ready
        sourceComponent: IllogicalImpulseFamily {}
    }
}
