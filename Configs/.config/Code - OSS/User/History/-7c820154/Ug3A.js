import Widget, {Button, Box, Label, Scrollable} from "resource:///com/github/Aylur/ags/widget.js";
import CodyAIService from "./AIService.js";
import Keys from "../../keys2.js";
import {QSState} from "../quicksettings/index.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import Gtk from "gi://Gtk?version=3.0";
import Gdk from "gi://Gdk";
import {readFile} from "resource:///com/github/Aylur/ags/utils.js";
import {Marked} from "../../node_modules/marked/lib/marked.esm.js";
import {markedHighlight} from "../../node_modules/marked-highlight/src/index.js";
import hljs from "../highlight.js/lib/index.js";
import { execAsync } from "resource:///com/github/Aylur/ags/utils.js";
import Menu from "../quicksettings/menu.js";
import { QuickSettingsPage } from "../quicksettings/quicksettings.js";
import icons from "../icons/index.js";
import Gio from "gi://Gio";
import GLib from "gi://GLib";
import GObject from "gi://GObject?version=2.0";
import GdkPixbuf from "gi://GdkPixbuf";
import ConfigService from "../config/index.js";

const CodyContainer = () => {
  // Implementation of CodyContainer
};const SettingsVisible = Variable(false);
const files = new Map();

function sendMessage(textView, filesContainer) {
  const buffer = textView.get_buffer();
  const [start, end] = buffer.get_bounds();
  const text = buffer.get_text(start, end, true);
  if (!text || text.length == 0) return;
  
  // Menyesuaikan pengiriman pesan untuk Cody AI
  CodyAIService.send(text, Array.from(files.values()));
  
  buffer.set_text("", -1);
  filesContainer.clear();
}

// Implementasi komponen UI lainnya seperti WebView, MessageContent, Message, dll.
// Sesuaikan dengan kebutuhan Cody AI

const CodyContainer = () => {
  const fileContainer = FilesContainer();
  const box = Box({
    class_name: "cody-container",
    vertical: true,
    children: [
      Widget.Revealer({
        reveal_child: SettingsVisible.bind(),
        child: SettingsContainer()
      }),
      Scrollable({
        class_name: "cody-message-list",
        hscroll: "never",
        vscroll: "always",
        vexpand: true,
        child: Box({vertical: true})
          .hook(CodyAI, (box, idx) => {
            const msg = CodyAI.messages[idx];
            if (!msg) return;
            const msgWidget = Message(msg, box.get_parent());
            box.add(msgWidget);
          }, "newMsg")
          .hook(CodyAI, box => {
            box.children = [];
          }, "clear")
      }),
      Box({
        class_name: "cody-entry-box",
        vertical: true,
        children: [
          fileContainer,
          Box({
            children: [
              TextEntry(fileContainer),
              Button({
                class_name: "cody-send-button",
                on_clicked: (btn) => {
                  // Implementasi untuk mengunggah file atau kode
                },
                child: Widget.Icon("edit-select-all-symbolic"),
              }),
              Button({
                class_name: "cody-send-button",
                on_clicked: (btn) => {
                  const textView = btn.get_parent().children[0].child;
                  sendMessage(textView, fileContainer);
                },
                label: "󰒊",
              }),
            ]
          })
        ]
      }),
    ],
  });
  return box;
};

const QSCodyAI = () => QuickSettingsPage(
  Menu({
    title: "Cody AI",
    icon: icons.ai,
    content: CodyContainer(),
    headerChild: Widget.Box({
      class_name: "spacing-5",
      children: [
        Widget.Button({
          on_clicked: () => CodyAI.clear(),
          child: Widget.Box({
            children: [
              Widget.Label("Clear "),
              Widget.Icon(icons.trash.empty),
            ]
          }),
        }),
        Widget.Button({
          on_clicked: () => SettingsVisible.value = !SettingsVisible.value,
          child: Widget.Icon(icons.settings)
        })
      ]
    })
  })
);

export default CodyContainer;
export {
  CodyContainer,
  QSCodyAI,
};
