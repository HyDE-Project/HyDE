import Widget, {Button, Box, Label, Scrollable} from "resource:///com/github/Aylur/ags/widget.js";
import waifu from "./AIService.js";
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
    waifu.send(msg);
  }
  else {
    waifu.send(text);
  }
  buffer.set_text("", -1);
}


try {
  const WebKit2 = (await import("gi://WebKit2?version=4.1")).default;

  const WebView = Widget.subclass(WebKit2.WebView, "AgsWebView");

  const parser = new Marked(
    markedHighlight({
      langPrefix: "hljs language-",
      /**
     * @param {string} code
     * @param {string} lang
     */
      highlight(code, lang) {
        const language = hljs.getLanguage(lang) ? lang : "plaintext";
        return hljs.highlight(code, {language}).value;
      }
    })
  );
  const renderer = {
  /**
   * @param {string} code
   * @param {string} language
   */
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


  // const styleString = readFile(`${App.configDir}/highlight.css`);
  // const stylesheet = new WebKit2.UserStyleSheet(
  // styleString, 0, 0, null, null);

  const FilesContainer = () => {

    const box = Widget.Box({
      vertical: true,
      attribute: {}
    });

    const FileWidget = (filePath, fileData) => {

      if(!fileData) fileData = `url(${filePath})`;
      else fileData = "data:image/png;base64," + fileData;

      const loader = new GdkPixbuf.PixbufLoader();
      const data = GLib.base64_decode(files.get(filePath).base64.trim());
      loader.write(data);
      loader.close();
      const pixbuf = loader.get_pixbuf();

      const fileBox = Widget.Box({
        attribute: filePath,
        class_name: "file-container spacing-5",
        children: [
          Widget.Icon({
            class_name: "ai-image",
            icon: pixbuf
          }),
          Widget.Label({
            truncate: "end",
            label: GLib.path_get_basename(filePath)
          }),
          Widget.Box({hexpand: true}),
          Widget.Button({
            child: Widget.Icon(icons.notifications.close),
            on_clicked: () => box.attribute.removeFile(filePath)
          })
        ]
      });
      return fileBox;
    };



    const addFilePath = (filePath, contentType) => {
      if(files.has(filePath)) return;
      const file = Gio.File.new_for_path(filePath);
      const [, contents, length] = file.load_contents(null);

      const content = GLib.base64_encode(contents);
      files.set(filePath, {
        mime: contentType,
        base64: content,
        filePath: filePath
      });
      box.add(FileWidget(filePath));
    };

    const addFileData = (fileData, contentType) => {
      const now = GLib.DateTime.new_now_local();
      const formattedTime = now.format("%Y-%m-%d %H:%M:%S");
      const fileName = `screenshot-${formattedTime}`;
      files.set(fileName, {
        mime: contentType,
        base64: fileData
      });
      box.add(FileWidget(fileName, fileData));
    };


    const removeFile = (filePath) => {
      files.delete(filePath);
      box.children.forEach(fileWidget => {
        if(fileWidget.attribute == filePath) fileWidget.destroy();
      });
    };

    box.attribute.addFilePath = addFilePath;
    box.attribute.addFileData = addFileData;
    box.attribute.removeFile = removeFile;

    return box;
  };

  /**
  * @param {import('modules/chatGPT/AIService').ChatGPTMessage} msg
  * @param {import('types/widget').Scrollable} scrollable
  */
  const MessageContent = (msg, scrollable) => {
    const view = WebView({
      class_name: "ai-msg-content",
      hexpand: true
    })
      .hook(msg, (view) => {
        let text = "";
        if(Array.isArray(msg.content)) {
          msg.content.forEach(entry => {
            if(entry.type == "text") text += entry.text;
            if(entry.type == "image_url") {
              if(entry.image_url.filePath) text += `![image](${entry.image_url.filePath})`;
              else text += `![image](${entry.image_url.url})`;
            }
          });
        }
        else {
          text = msg.content;
        }
        const parsed = parser.parse(text);
        const content = `<script>
            function copyCode(button, encodedCode) {
              const decodedCode = decodeURIComponent(encodedCode);
              const tempElement = document.createElement('pre');
              tempElement.innerHTML = decodedCode;
              navigator.clipboard.writeText(tempElement.innerText);
              button.innerText = 'Copied';
              setTimeout(() => button.innerText = 'Copy', 2000);
            }</script>` + parsed;//parser.parse(msg.content);
        view.load_html(content, "file://");
      }, "notify::content")
      .on("load-changed", /** @param {WebKit2.WebView} view, @param {WebKit2.LoadEvent} event*/(view, event) => {
        if (event === 3) {
          view.evaluate_javascript("document.body.scrollHeight", -1, null, null, null, (view, result) => {
            const height = view.evaluate_javascript_finish(result)?.to_int32() || -1;
            view.get_parent().css = `min-height: ${height}px;`;
            // @ts-ignore
            const adjustment = scrollable.get_vadjustment();
            adjustment.set_value(adjustment.get_upper() - adjustment.get_page_size());
          });
        }
      })
    // HACK: evil way to disable context menu
      .on("context-menu", (view, menu) => {
        menu.remove_all();
      })
      .on("decide-policy", (view, decision, type) => {
        if(type != 0) {
          decision.ignore();
          return;
        }
        const uri = decision.get_request().get_uri();
        if (uri === "file:///") {
          decision.use();
          return;
        }
        decision.ignore();
        execAsync(["xdg-open", uri]);
      });
    view.get_settings().set_javascript_can_access_clipboard(true);
    view.get_settings().set_enable_write_console_messages_to_stdout(true);
    // HACK: style context is only accessable after the widget was added to the
    // hierachy, so i do this to set the color once.
    view.on("realize", () => {
      const bgCol = view.get_style_context().get_property("background-color", Gtk.StateFlags.NORMAL);
      view.set_background_color(bgCol);
    });
    view.hook(ConfigService, () => {
      const styleString = readFile(`${App.configDir}/highlight.css`);
      const stylesheet = new WebKit2.UserStyleSheet(
        styleString, 0, 0, null, null);
      view.get_user_content_manager().add_style_sheet(stylesheet);
    }, "css-changed");

    return Box({
      css: "padding: 1px",
      children: [view]
    });
  };

  /**
  * @param {import('modules/chatGPT/AIService').ChatGPTMessage} msg
  * @param {import('types/widget').Scrollable} scrollable
  */
  const Message = (msg, scrollable) => Box({
    class_name: `ai-message ${msg.role}`,
    vertical: true,
    children: [
      Label({
        label: Keys[msg.role] || msg.role,
        xalign: 0,
        class_name: `ai-role ${msg.role}`,
        hexpand: true,
        wrap: true,
      }),
      MessageContent(msg, scrollable),
    ]
  });

  const TextEntry = (fileContainer) => {
    const placeholder = "Ask ChatGPT";
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
          waifu.clear();
        }
        else if (event.get_keyval()[1] === Gdk.KEY_Return && state == 0) {
          sendMessage(entry, fileContainer);
          return true;
        }

      })
      .on("drag-data-received", (entry, context, x, y, data, info, time) => {
        if (data.get_length() > 0) {
          let uris = data.get_uris();

          for (let uri of uris) {
            const file = Gio.File.new_for_uri(uri);
            const filePath = file.get_path();

            const buffer = textView.get_buffer();
            const iter = buffer.get_end_iter();
            const contentType = file.query_info("standard::content-type", Gio.FileQueryInfoFlags.NONE, null).get_content_type();
            if(contentType?.startsWith("text/")) {
              Utils.readFileAsync(file).then(content => {
                const [start, end] = buffer.get_bounds();
                const text = buffer.get_text(start, end, true);
                if(text === placeholder) buffer.set_text(content, -1);
                else buffer.insert(iter, content, -1);
              });
            }
            else if(contentType?.startsWith("image/")) {
              fileContainer.attribute.addFilePath(filePath, contentType);
            }
          }
          Gtk.drag_finish(context, true, false, time);
        } else {
          Gtk.drag_finish(context, false, false, time);
        }
        return true;
      })
      .hook(QSState, (entry) => {
        if (QSState.value === "ChatGPT")
          entry.grab_focus();
      })
      .hook(App, (entry, window, visible) => {
        if (window === "quicksettings" && visible && QSState.value === "ChatGPT")
          entry.grab_focus();
      });

    const dndTarget = new Gtk.TargetEntry("text/uri-list", 0, 0);
    textView.drag_dest_set(Gtk.DestDefaults.ALL, [dndTarget], Gdk.DragAction.COPY | Gdk.DragAction.MOVE);


    return Scrollable({
      child: textView,
      max_content_height: 100,
      propagate_natural_height: true,
      vscroll: "automatic",
      hscroll: "never",
    });
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
              waifu.getModels().forEach(item => {
                self.append(item, item);
              });
              waifu.bind_property(
                "model",
                self,
                "active-id",
                GObject.BindingFlags.BIDIRECTIONAL | GObject.BindingFlags.SYNC_CREATE
              );
            }
          })
        ]
      }),
      Box({
        children: [
          Label({
            label: "Temperature:"
          }),
          Box({hexpand: true}),
          Widget.SpinButton({
            range: [0, 2],
            increments: [0.1, 0.5],
            digits: 1,
            setup: (self) => {
              waifu.bind_property(
                "temperature",
                self,
                "value",
                GObject.BindingFlags.BIDIRECTIONAL | GObject.BindingFlags.SYNC_CREATE
              );
            }
          })
        ]
      }),
      Box({
        class_name: "spacing-5",
        vertical: true,
        children: [
          Label({
            hpack: "start",
            label: "System message:"
          }),
          Scrollable({
            child: Widget.TextView({
              class_name: "system-message",
              wrap_mode: Gtk.WrapMode.WORD_CHAR,
              hexpand: true,
              setup: (self) => {
                waifu.bind_property(
                  "system-message",
                  self.get_buffer(),
                  "text",
                  GObject.BindingFlags.BIDIRECTIONAL | GObject.BindingFlags.SYNC_CREATE
                );
              }
            }),
            max_content_height: 150,
            min_content_height: 50,
            propagate_natural_height: true,
            vscroll: "automatic",
            hscroll: "never",
          })
        ]
      })
    ]
  });


  AIContainer = () => {

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
            //prevent jump to the top of clicked element
            // @ts-ignore
            viewport.set_focus_vadjustment(new Gtk.Adjustment(undefined));
          },
          child: Box({vertical: true})
            .hook(waifu, (box, idx) => {
              const msg = waifu.messages[idx];
              if (!msg) return;
              const msgWidget = Message(msg, box.get_parent());
              box.add(msgWidget);
            }, "newMsg")
            .hook(waifu, box => {
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
                    // @ts-ignore
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
}
catch(e) {
  AIContainer = () => Widget.Box();
  console.warn("webkit2gtk-4.1 is not installed. ChatGPT module has been disabled.");
}

/**
 * @returns {import('types/@girs/gtk-3.0/gtk-3.0').Gtk.Widget}
 */
const QSChatGPT = () => QuickSettingsPage(
  Menu({
    title: "ChatGPT",
    icon: icons.ai,
    content: AIContainer(),
    headerChild: Widget.Box({
      class_name: "spacing-5",
      children: [
        Widget.Button({
          on_clicked: () => waifu.clear(),
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
  QSChatGPT,
};
