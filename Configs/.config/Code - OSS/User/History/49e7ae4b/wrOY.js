import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import {timeout, execAsync} from "resource:///com/github/Aylur/ags/utils.js";
import RoundedCorner from "../roundedCorner/index.js";
import StackState from "../stackState/stackState.js";
import icons from "../icons/index.js";
import { Quicksettings } from "./quicksettings.js";
import { exec } from "types/utils/exec.js";

export const QSState = new StackState("Audio");

const ModuleSettingsIcon = (props = {}) => Widget.Button({
  ...props,
  class_name: "qs-switcher-button",
  tooltip_text: "Open Settings",
  on_clicked: () => {
    execAsync(["bash", "-c", "XDG_CURRENT_DESKTOP=\"gnome\" gnome-control-center"]);
    App.toggleWindow("quicksettings");
  },
  child: Widget.Icon({
    icon: icons.header.settings
  })
});

const ModulePowerIcon = (props = {}) => Widget.Button({
  ...props,
  class_name: "qs-switcher-button",
  tooltip_text: "Session",
  on_clicked: () => {
    execAsync(["bash", "-c", "$HOME/.local/share/bin/logoutlaunch.sh"]);
    //App.toggleWindow("session");
    //App.closeWindow("quicksettings");
  },
  child: Widget.Icon({
    icon: icons.header.power
  })
});

const SettingsButtons = () => Widget.Box({
  vertical: true,
  children: [
    ModuleSettingsIcon(),
    ModulePowerIcon()
  ]
});

/**
 * @param {string} item
 */
const StackSwitcherButton = item => Widget.Button({
  class_name: "qs-switcher-button",
  tooltip_text: item,
  child: Widget.Icon(icons.quicksettings[item.toLowerCase()] || "image-missing"),
  on_clicked: () => QSState.value = item,
})
  .hook(QSState, button => {
    button.toggleClassName("focused", QSState.value == item);
    const focusedID = QSState.items.indexOf(QSState.value);
    button.toggleClassName("before-focused", QSState.items[focusedID-1] == item);
    button.toggleClassName("after-focused", QSState.items[focusedID+1] == item);
  });

/**
 * @param {boolean} start
 */
const StackSwitcherPadding = start => Widget.Box({
  class_name: "qs-switcher-button",
  vexpand: true,
  children: [Widget.Icon()]
})
  .hook(QSState, (box) => {
    const focusedID = QSState.items.indexOf(QSState.value);
    box.toggleClassName("before-focused", start && focusedID == 0);
    box.toggleClassName("after-focused", !start && focusedID == QSState.items.length - 1);
  });
/**
 * @param {string[]} items
 */
const StackSwitcher = items => Widget.Box({
  vertical: true,
  class_name: "qs-switcher",
  children: [
    StackSwitcherPadding(true),
    ...items.map(i => StackSwitcherButton(i)),
    StackSwitcherPadding(false),
    SettingsButtons(),
  ]
});

const QSStack = () => Widget.Stack({
  visible_child_name: QSState.bind(),
  transition: "over_left",
  class_name: "quicksettings",
  children: {
    ...Quicksettings()
  }
});

export default () => {
  const stack = QSStack();
  QSState.items = Object.keys(stack.children);
  const stackSwitcher = StackSwitcher(Object.keys(stack.children));
  const window =  Widget.Window({
    keymode: "exclusive",
    visible: false,
    anchor: ["right", "top", "bottom"],
    name: "quicksettings",
    child: Widget.Box({
      css: "padding-left: 2px",
      children: [
        Widget.Box({
          children: [
            Widget.Overlay({
              child: Widget.Box({
                children: [
                  Widget.Box({css: "min-width: 1rem"}),
                  Widget.Revealer({
                    reveal_child: false,
                    child: stack,
                    transition_duration: 350,
                    transition: "slide_left"
                  }).hook(App, (revealer, name, visible) => {
                    if (name === "quicksettings") {
                      if(visible) timeout(100, () => revealer.reveal_child = visible);
                      else revealer.reveal_child = visible;
                    }
                  }),
                ]
              }),
              overlays: [
                RoundedCorner("topright", {class_name: "corner"}),
                RoundedCorner("bottomright", {class_name: "corner"}),
              ]
            }),
          ]
        }),
        Widget.Revealer({
          reveal_child: false,
          transition: "slide_left",
          transition_duration: 350,
          child: stackSwitcher,
        }).hook(App, (revealer, name, visible) => {
          if (name === "quicksettings") {
            if(visible) revealer.reveal_child = visible;
            else timeout(100, () => revealer.reveal_child = visible);
          }
        })
      ]
    })
  });

  const addKeyBinds = (mods) => {
    window.keybind("Escape", () => App.closeWindow("quicksettings"));
    window.keybind(mods, "Tab", () => QSState.next());
    for (let i = 0; i < 10; i++) {
      window.keybind(mods, `${i}`, () => QSState.setIndex(i));
      window.keybind(mods, `KP_${i}`, () => QSState.setIndex(i));
    }
  };
  addKeyBinds(["MOD1"]);
  addKeyBinds(["MOD1", "MOD2"]);
  return window;
};

