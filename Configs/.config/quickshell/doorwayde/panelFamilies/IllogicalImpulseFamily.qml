// DOORwayDE QuickShell — bar-only panel family (Phase 12).
// Sidebars (Phase 13), OSD/notifications (Phase 15), session (Phase 16) follow.
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.ii.bar

Scope {
    // Phase 12: top bar only. Horizontal bar, not vertical.
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }

    // Phase 13: right sidebar (system controls) + left sidebar (productivity)
    // Phase 15: notification popups + OSD overlays
    // Phase 16: session screen (replaces wlogout)
}
