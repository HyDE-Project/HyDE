// DOORwayDE QuickShell — Phase 15: bar + sidebars + OSD + notification popups.
// Session screen (Phase 16) follows.
import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.ii.bar
import qs.modules.ii.sidebarLeft
import qs.modules.ii.sidebarRight
import qs.modules.ii.osd
import qs.modules.ii.notifications

Scope {
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: Bar {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: SidebarRight {} }
    PanelLoader { component: Osd {} }
    PanelLoader { component: NotificationPopups {} }

    // Phase 16: session screen (replaces wlogout)
}
