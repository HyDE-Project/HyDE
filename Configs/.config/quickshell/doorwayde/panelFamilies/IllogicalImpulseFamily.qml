// DOORwayDE QuickShell — Phase 13: bar + right sidebar.
// Left sidebar (Phase 14), OSD/notifications (Phase 15), session (Phase 16) follow.
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.ii.bar
import qs.modules.ii.sidebarRight

Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { component: SidebarRight {} }

    // Phase 14: left sidebar (productivity)
    // Phase 15: notification popups + OSD overlays
    // Phase 16: session screen (replaces wlogout)
}
