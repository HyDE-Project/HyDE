// DOORwayDE QuickShell — Phase 15: volume/brightness on-screen display.
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: osdScope
    property string activeType: "volume"

    Connections {
        target: Brightness
        function onBrightnessChanged() {
            osdScope.activeType = "brightness";
            GlobalStates.osdBrightnessOpen = true;
            GlobalStates.osdVolumeOpen = false;
            osdHideTimer.restart();
        }
    }

    Connections {
        target: Audio
        function onValueChanged() {
            osdScope.activeType = "volume";
            GlobalStates.osdVolumeOpen = true;
            GlobalStates.osdBrightnessOpen = false;
            osdHideTimer.restart();
        }
    }

    Timer {
        id: osdHideTimer
        interval: 2000
        onTriggered: {
            GlobalStates.osdBrightnessOpen = false;
            GlobalStates.osdVolumeOpen = false;
        }
    }

    PanelWindow {
        id: osdPanel
        visible: GlobalStates.osdBrightnessOpen || GlobalStates.osdVolumeOpen
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        color: "transparent"

        anchors { bottom: true }
        margins { bottom: Appearance.sizes.hyprlandGapsOut * 2 + 8 }

        width: 280
        height: 64

        readonly property real brightnessValue: Brightness.monitors[0]?.brightness ?? 0
        readonly property real volumeValue: Audio.value ?? 0
        readonly property bool isBrightness: osdScope.activeType === "brightness"

        StyledRectangularShadow {
            target: osdPill
        }

        Rectangle {
            id: osdPill
            anchors.centerIn: parent
            width: parent.width - 8
            height: parent.height - 8
            radius: height / 2
            color: Appearance.colors.colLayer0
            border.width: 1
            border.color: Appearance.colors.colLayer0Border

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                MaterialSymbol {
                    text: osdPanel.isBrightness
                        ? (Hyprsunset.gamma < 100 ? "wb_twilight" : "light_mode")
                        : (Audio.sink?.audio.muted ? "volume_off"
                            : osdPanel.volumeValue > 0.66 ? "volume_up"
                            : osdPanel.volumeValue > 0.33 ? "volume_down"
                            : "volume_mute")
                    iconSize: 20
                    color: Appearance.colors.colOnLayer0
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    value: osdPanel.isBrightness
                        ? osdPanel.brightnessValue
                        : Math.min(1.0, osdPanel.volumeValue)
                }

                StyledText {
                    text: osdPanel.isBrightness
                        ? Math.round(osdPanel.brightnessValue * 100) + "%"
                        : Math.round(osdPanel.volumeValue * 100) + "%"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer0
                    Layout.minimumWidth: 36
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
