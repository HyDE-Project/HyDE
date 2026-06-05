// DOORwayDE QuickShell — Phase 15: floating notification popup overlay.
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    PanelWindow {
        visible: Notifications.popupList.length > 0
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:notificationPopups"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { top: true; right: true }
        margins {
            top: Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut
            right: Appearance.sizes.hyprlandGapsOut
        }

        width: 420
        height: 600

        NotificationListView {
            popup: true
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                margins: 5
            }
            height: Math.min(590, contentHeight)
        }
    }
}
