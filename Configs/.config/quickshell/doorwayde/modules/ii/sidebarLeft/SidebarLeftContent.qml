import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sidebarLeft.notes
import qs.modules.ii.sidebarLeft.overview
import qs.modules.ii.sidebarLeft.scratchpads
import qs.modules.ii.sidebarRight.todo
import qs.modules.ii.sidebarRight.pomodoro
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property int sidebarPadding: 10

    implicitHeight: bg.implicitHeight
    implicitWidth: bg.implicitWidth

    StyledRectangularShadow { target: bg }

    Rectangle {
        id: bg
        anchors.fill: parent
        implicitHeight: parent.height - Appearance.sizes.hyprlandGapsOut * 2
        implicitWidth: Appearance.sizes.sidebarWidth - Appearance.sizes.hyprlandGapsOut * 2
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
        clip: true

        ColumnLayout {
            anchors {
                fill: parent
                margins: sidebarPadding
            }
            spacing: sidebarPadding

            ToolbarTabBar {
                id: tabBar
                Layout.alignment: Qt.AlignHCenter
                tabButtonList: [
                    { name: qsTr("Notes"),       icon: "edit_note" },
                    { name: qsTr("Overview"),    icon: "grid_view" },
                    { name: qsTr("Tasks"),       icon: "checklist" },
                    { name: qsTr("Scratchpads"), icon: "layers" }
                ]
                Component.onCompleted: {
                    if (Persistent.ready)
                        setCurrentIndex(Persistent.states.sidebar.leftTab ?? 0);
                }
                onCurrentIndexChanged: {
                    if (Persistent.ready)
                        Persistent.states.sidebar.leftTab = currentIndex;
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex

                Notes {}

                Overview {}

                // Tasks tab — shares state with the right sidebar's todo/pomodoro widgets
                ColumnLayout {
                    spacing: sidebarPadding
                    TodoWidget   { Layout.fillWidth: true }
                    PomodoroWidget {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                Scratchpads {}
            }
        }
    }
}
