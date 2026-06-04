import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    readonly property string notesDir: {
        const xdg = Quickshell.env("XDG_DATA_HOME");
        const home = Quickshell.env("HOME");
        return (xdg || home + "/.local/share") + "/doorwayde/notes";
    }
    readonly property string notesFile: root.notesDir + "/scratchpad.md"

    FileView {
        id: notesView
        path: Qt.resolvedUrl(root.notesFile)
        onLoaded: editor.text = notesView.text()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                Quickshell.execDetached(["bash", "-c", `mkdir -p '${root.notesDir}'`]);
                notesView.setText("");
            }
        }
        Component.onCompleted: reload()
    }

    // Debounce writes — flush 500ms after the user stops typing.
    Timer {
        id: saveTimer
        interval: 500
        repeat: false
        onTriggered: notesView.setText(editor.text)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            StyledText {
                text: qsTr("Notes")
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
            }

            ToolbarButton {
                icon.name: "save"
                implicitWidth: 32
                implicitHeight: 32
                onClicked: {
                    const ts = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
                    Quickshell.execDetached(["bash", "-c",
                        `mkdir -p '${root.notesDir}' && cp '${root.notesFile}' '${root.notesDir}/${ts}.md' 2>/dev/null || true`
                    ]);
                }
                StyledToolTip { text: qsTr("Save timestamped copy") }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.vertical: StyledScrollBar {}

            StyledTextArea {
                id: editor
                width: parent.width
                wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
                placeholderText: qsTr("Write markdown notes here…")
                background: null
                onTextChanged: saveTimer.restart()
            }
        }
    }
}
