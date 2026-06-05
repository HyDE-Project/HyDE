// DOORwayDE QuickShell — left sidebar (productivity panel, Phase 14).
import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth

    PanelWindow {
        id: panelWindow
        visible: GlobalStates.sidebarLeftOpen

        function hide() {
            GlobalStates.sidebarLeftOpen = false;
        }

        exclusiveZone: 0
        implicitWidth: sidebarWidth
        WlrLayershell.namespace: "quickshell:sidebarLeft"
        WlrLayershell.keyboardFocus: GlobalStates.sidebarLeftOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        anchors {
            top: true
            left: true
            bottom: true
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() { panelWindow.hide(); }
        }

        Loader {
            active: GlobalStates.sidebarLeftOpen
            anchors {
                fill: parent
                margins: Appearance.sizes.hyprlandGapsOut
                rightMargin: Appearance.sizes.elevationMargin
            }
            focus: GlobalStates.sidebarLeftOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) panelWindow.hide();
            }
            sourceComponent: SidebarLeftContent {}
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen; }
        function close():  void { GlobalStates.sidebarLeftOpen = false; }
        function open():   void { GlobalStates.sidebarLeftOpen = true; }
    }

    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"
        onPressed: { GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen; }
    }
}
