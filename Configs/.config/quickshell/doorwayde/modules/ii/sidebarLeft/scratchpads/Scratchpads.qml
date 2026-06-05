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

    Connections {
        target: GlobalStates
        function onSidebarLeftOpenChanged() {
            if (GlobalStates.sidebarLeftOpen) HyprlandData.updateWindowList();
        }
    }

    readonly property var scratchWindows: HyprlandData.windowList.filter(
        w => w.workspace?.name?.startsWith("special:")
    )

    function wsName(full) {
        return full?.startsWith("special:") ? full.slice(8) : full ?? "";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: qsTr("Scratchpads")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }
            ToolbarButton {
                icon.name: "move_down"
                implicitWidth: 32; implicitHeight: 32
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                    "movetoworkspacesilent", "special:main"])
                StyledToolTip { text: qsTr("Move focused window to special:main") }
            }
        }

        FadeLoader {
            shown: root.scratchWindows.length === 0
            Layout.fillWidth: true
            sourceComponent: StyledText {
                text: qsTr("No scratchpad windows")
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
                id: scratchList
                model: root.scratchWindows
                spacing: 2

                delegate: ItemDelegate {
                    required property var modelData
                    width: scratchList.width
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
                                text: root.wsName(modelData.workspace?.name)
                                font.pixelSize: Appearance.font.pixelSize.tiny
                                color: Appearance.colors.colOutline
                            }
                        }
                    }
                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch",
                        "togglespecialworkspace",
                        root.wsName(modelData.workspace?.name)])
                }
            }
        }
    }
}
