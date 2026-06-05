import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    // Session action button: circular ripple button + label below.
    component SessionButton: ColumnLayout {
        id: btn
        required property string icon
        required property string label
        required property var action
        property bool destructive: false
        spacing: 10

        RippleButton {
            id: rippleBtn
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 80
            implicitHeight: 80
            buttonRadius: Appearance.rounding.full
            colBackground: btn.destructive
                ? Qt.rgba(Appearance.m3colors.m3error.r, Appearance.m3colors.m3error.g, Appearance.m3colors.m3error.b, 0.15)
                : Qt.rgba(Appearance.colors.colLayer1.r, Appearance.colors.colLayer1.g, Appearance.colors.colLayer1.b, 0.7)
            colBackgroundHover: btn.destructive
                ? Qt.rgba(Appearance.m3colors.m3error.r, Appearance.m3colors.m3error.g, Appearance.m3colors.m3error.b, 0.28)
                : Qt.rgba(Appearance.colors.colLayer1Hover.r, Appearance.colors.colLayer1Hover.g, Appearance.colors.colLayer1Hover.b, 0.9)
            colRipple: btn.destructive ? Appearance.m3colors.m3error : Appearance.colors.colLayer1Active
            onClicked: {
                GlobalStates.sessionOpen = false;
                btn.action();
            }
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: btn.icon
                iconSize: 36
                color: btn.destructive ? Appearance.m3colors.m3error : Appearance.colors.colOnLayer0
            }
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: btn.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: "white"
            opacity: 0.85
        }
    }

    IpcHandler {
        target: "sessionScreen"
        function open():  void { GlobalStates.sessionOpen = true; }
        function close(): void { GlobalStates.sessionOpen = false; }
        function toggle(): void { GlobalStates.sessionOpen = !GlobalStates.sessionOpen; }
    }

    PanelWindow {
        id: sessionWindow
        visible: GlobalStates.sessionOpen
        exclusiveZone: -1
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell:session"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }

        // Scrim background — clicking it closes the screen.
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: sessionWindow.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.animationCurves.expressiveEffects
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: GlobalStates.sessionOpen = false
            }

            Keys.onEscapePressed: GlobalStates.sessionOpen = false

            // Floating card centered on screen.
            Rectangle {
                id: card
                anchors.centerIn: parent
                width: buttonsGrid.implicitWidth + 80
                height: buttonsGrid.implicitHeight + 80
                radius: Appearance.rounding.large ?? 24
                color: Qt.rgba(
                    Appearance.m3colors.m3surfaceContainer.r,
                    Appearance.m3colors.m3surfaceContainer.g,
                    Appearance.m3colors.m3surfaceContainer.b,
                    0.85
                )

                MouseArea {
                    anchors.fill: parent
                    // Absorb clicks so scrim MouseArea doesn't close the window.
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 28

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: qsTr("Session")
                        font {
                            pixelSize: Appearance.font.pixelSize.huge
                            family: Appearance.font.family.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                        color: "white"
                        opacity: 0.9
                    }

                    GridLayout {
                        id: buttonsGrid
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3
                        rowSpacing: 20
                        columnSpacing: 24

                        SessionButton {
                            icon: "lock"
                            label: qsTr("Lock")
                            action: Session.lock
                        }
                        SessionButton {
                            icon: "bedtime"
                            label: qsTr("Suspend")
                            action: Session.suspend
                        }
                        SessionButton {
                            icon: "downloading"
                            label: qsTr("Hibernate")
                            action: Session.hibernate
                        }
                        SessionButton {
                            icon: "logout"
                            label: qsTr("Logout")
                            action: Session.logout
                            destructive: true
                        }
                        SessionButton {
                            icon: "restart_alt"
                            label: qsTr("Reboot")
                            action: Session.reboot
                            destructive: true
                        }
                        SessionButton {
                            icon: "power_settings_new"
                            label: qsTr("Shutdown")
                            action: Session.poweroff
                            destructive: true
                        }
                    }
                }
            }
        }
    }
}
