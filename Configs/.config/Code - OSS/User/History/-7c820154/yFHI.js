import Widget, {Button, Box, Label, Scrollable} from "resource:///com/github/Aylur/ags/widget.js";
import CodyAI from "./AIService.js";
import { TOKEN } from "./Token.js";
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

let CodyAIContainer;
const SettingsVisible = Variable(false);
const files = new Map();

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
import { AIService } from './AIService.js';

export const AIWidget = () => {
  if (!AIService.isAvailable()) {
      return {
          type: 'box',
          children: [{
              type: 'label',
              label: 'CodyAI is not available. Please install webkit2gtk-4.1.',
          }],
      };
  }
    
  const WebKit2 = (await import("gi://WebKit2?version=4.1")).default;

  const WebView = Widget.subclass(WebKit2.WebView, "AgsWebView");

  const parser = new Marked(
      markedHighlight({
          langPrefix: "hljs language-",
          highlight(code, lang) {
              const language = hljs.getLanguage(lang) ? lang : "plaintext";
              return hljs.highlight(code, {language}).value;
          }
      })
  );
  const renderer = {
      code(code, language) {
          language ||= "plaintext";
          const encoded = encodeURIComponent(code);
          return `
              <div class="code">
                  <div class="code-header"><span data-language="${language}">${language}</span><button onClick="copyCode(this, '${encoded}')">Copy</button></div>
                  <pre><code>${code}</code></pre>
              </div>`;
      }
  };

  parser.use({renderer});

  const FilesContainer = () => {
      // ... (FilesContainer implementation remains the same)
  };

  const Message = (msg, scrollable) => Box({
      class_name: `ai-message ${msg.role}`,
      vertical: true,
      children: [
          Label({
              label: TOKEN[msg.role] || msg.role,
              xalign: 0,
              class_name: `ai-role ${msg.role}`,
              hexpand: true,
              wrap: true,
          }),
          MessageContent(msg, scrollable),
      ]
  });

  const TextEntry = (fileContainer) => {
      // ... (TextEntry implementation remains the same)
  };

  const SettingsContainer = () => Box({
      class_name: "spacing-5 settings-container",
      vertical: true,
      children: [
          Box({
              children: [
                  Label({
                      label: "Model:"
                  }),
                  Box({hexpand: true}),
                  Widget.ComboBoxText({
                      setup: (self) => {
                          CodyAI.getModels().forEach(item => {
                              self.append(item, item);
                          });
                          CodyAI.bind_property(
                              "model",
                              self,
                              "active-id",
                              GObject.BindingFlags.BIDIRECTIONAL | GObject.BindingFlags.SYNC_CREATE
                          );
                      }
                  })
              ]
          }),
          // Add more CodyAI-specific settings here
      ]
  });

  const CodyAIContainer = () => {
      const fileContainer = FilesContainer();
      const box = Box({
          class_name: "ai-container",
          vertical: true,
          children: [
              Widget.Revealer({
                  reveal_child: SettingsVisible.bind(),
                  child: SettingsContainer()
              }),
              Scrollable({
                  class_name: "ai-message-list",
                  hscroll: "never",
                  vscroll: "always",
                  vexpand: true,
                  setup: self => {
                      const viewport = self.child;
                      viewport.set_focus_vadjustment(new Gtk.Adjustment(undefined));
                  },
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
                  class_name: "ai-entry-box",
                  vertical: true,
                  children: [
                      fileContainer,
                      Box({
                          children: [
                              TextEntry(fileContainer),
                              Button({
                                  class_name: "ai-send-button",
                                  on_clicked: (btn) => {
                                      Utils.execAsync("bash -c 'slurp | grim -g - - | base64 -w0'")
                                          .then(img => {
                                              fileContainer.attribute.addFileData(img, "image/png");
                                          });
                                  },
                                  child: Widget.Icon("edit-select-all-symbolic"),
                              }),
                              Button({
                                  class_name: "ai-send-button",
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

  return CodyAIContainer();
};
const QSCodyAI = () => QuickSettingsPage(
  Menu({
    title: "CodyAI",
    icon: icons.ai,
    content: CodyAIContainer(),
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

export default CodyAIContainer;
export {
  CodyAIContainer,
  QSCodyAI,
};

if (!TOKEN) {
  console.error("CodyAI: API Key is not set!");
}
