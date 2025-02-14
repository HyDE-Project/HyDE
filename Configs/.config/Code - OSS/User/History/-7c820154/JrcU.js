import Widget, {Button, Box, Label, Scrollable} from "resource:///com/github/Aylur/ags/widget.js";
import CodyAI from "./AIService.js";
import Keys from "../../keys.js";
import {QSState} from "../quicksettings/index.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import Gtk from "gi://Gtk?version=3.0";
import Gdk from "gi://Gdk";
import {readFile} from "resource:///com/github/Aylur/ags/utils.js";
import {Marked} from "../../node_modules/marked/lib/marked.esm.js";
// @ts-ignore
import {markedHighlight} from "../../node_modules/marked-highlight/src/index.js";
//highlightjs requires some modifications to work with gjs, mainly just how it's exported
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

let AIContainer;
const SettingsVisible = Variable(false);
const files = new Map();

/**
* @param {import('modules/widgets/widgets').TextView} textView
*/
function sendMessage(textView, filesContainer) {
  const buffer = textView.get_buffer();
  const [start, end] = buffer.get_bounds();
  const text = buffer.get_text(start, end, true);
  if (!text || text.length == 0) return;
  if(files.size > 0) {
    const msg = [{"type": "text", "text": text}];
    files.forEach((v, k) => {
      msg.push({
        "type": "image_url",
        "image_url": {
          "url": `data:${v.mime};base64,${v.base64}`,
          "filePath": v.filePath
        }
      }),
      filesContainer.attribute.removeFile(k);
    });
    CodyAI.send(msg);
  }
  else {
    CodyAI.send(text);
  }
  buffer.set_text("", -1);
}

// ... (rest of the code remains the same, just replace ChatGPT with CodyAI)

const TextEntry = (fileContainer) => {
    const placeholder = "Ask CodyAI";
    const textView = Widget.TextView({
      class_name: "ai-entry",
      wrap_mode: Gtk.WrapMode.WORD_CHAR,
      hexpand: true,
    })
      .on("focus-in-event", () => {
        const buffer = textView.get_buffer();
        const [start, end] = buffer.get_bounds();
        const text = buffer.get_text(start, end, true);
        if(text === placeholder) buffer.set_text("", -1);
      })
      .on("focus-out-event", () => {
        const buffer = textView.get_buffer();
        const [start, end] = buffer.get_bounds();
        const text = buffer.get_text(start, end, true);
        if(text === "") buffer.set_text(placeholder, -1);
      })
      .on("key-press-event", (entry, event) => {
        const keyval = event.get_keyval()[1];
        const state = event.get_state()[1] & ~Gdk.ModifierType.MOD2_MASK;
        if (
          (keyval === Gdk.KEY_C)
      && (state === (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK))) {
          CodyAI.clear();
        }
        else if (event.get_keyval()[1] === Gdk.KEY_Return && state == 0) {
          sendMessage(entry, fileContainer);
          return true;
        }

      })
      // ... (rest of the TextEntry code remains the same)

// ... (rest of the code remains the same)

/**
 * @returns {import('types/@girs/gtk-3.0/gtk-3.0').Gtk.Widget}
 */
const QSCodyAI = () => QuickSettingsPage(
  Menu({
    title: "CodyAI",
    icon: icons.ai,
    content: AIContainer(),
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

export default AIContainer;
export {
  AIContainer,
  QSCodyAI,
};
