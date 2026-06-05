import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    // Refresh when the sidebar opens or the active window changes.
    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) HyprlandData.updateWindowList();
        }
    }
    Connections {
        target: Hyprland
        function onActiveWindowChanged() { HyprlandData.updateWindowList(); }
    }

    readonly property var openWindows: HyprlandData.windowList.filter(
        w => w.workspace?.name && !w.workspace.name.startsWith("special:")
    )

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: qsTr("Open Windows")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
            ToolbarButton {
                icon.name: "refresh"
                implicitWidth: 32; implicitHeight: 32
                onClicked: HyprlandData.updateWindowList()
                StyledToolTip { text: qsTr("Refresh") }
            }
        }

        FadeLoader {
            shown: root.openWindows.length === 0
            Layout.fillWidth: true
            sourceComponent: StyledText {
                text: qsTr("No open windows")
                opacity: 0.5
                color: Appearance.colors.colOnLayer0
                font.pixelSize: Appearance.font.pixelSize.small
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: StyledScrollBar {}

            ListView {
                id: winList
                model: root.openWindows
                spacing: 2

                delegate: ItemDelegate {
                    required property var modelData
                    width: winList.width
                    height: 52
                    padding: 8
                    background: Rectangle {
                        color: parent.hovered
                            ? Appearance.colors.colLayer1Hover : "transparent"
                        radius: Appearance.rounding.small
                    }
                    contentItem: RowLayout {
                        spacing: 8
                        CustomIcon {
                            implicitWidth: 24; implicitHeight: 24
                            source: modelData.class?.toLowerCase() ?? ""
                        }
                        ColumnLayout {
                            spacing: 2
                            StyledText {
                                text: modelData.title ?? ""
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                            }
                            StyledText {
                                text: (modelData.class ?? "") + "  ·  ws " + (modelData.workspace?.id ?? "")
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.pixelSize: Appearance.font.pixelSize.tiny
                                color: Appearance.colors.colOnLayer0
                                opacity: 0.6
                            }
                        }
                    }
                    onClicked: {
                        Quickshell.execDetached(["hyprctl", "dispatch",
                            "focuswindow", "address:" + modelData.address]);
                        GlobalStates.sidebarLeftOpen = false;
                    }
                }
            }
        }
    }
}
