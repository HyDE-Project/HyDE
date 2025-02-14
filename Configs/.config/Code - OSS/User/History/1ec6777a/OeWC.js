import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import {timeout, exec} from "resource:///com/github/Aylur/ags/utils.js";
import SearchBox from "./search.js";
import RoundedCorner from "../roundedCorner/index.js";
import Categories from "./categories.js";
import FirefoxBox from "./firefox.js";
import StackState from "../stackState/stackState.js";
import icons from "../icons/index.js";
import GLib from "gi://GLib";
const LauncherState = new StackState("Search");

/**
 * @param {string} item
 */
const StackSwitcherButton = item => Widget.Button({
  class_name: "launcher-switcher-button",
  tooltip_text: item,
  child: Widget.Icon(icons.launcher[item.toLowerCase()] || "image-missing"),
  on_clicked: () => LauncherState.value = item,
})
  .hook(LauncherState, button => {
    button.toggleClassName("focused", LauncherState.value == item);
    const focusedID = LauncherState.items.indexOf(LauncherState.value);
    button.toggleClassName("before-focused", LauncherState.items[focusedID-1] == item);
    button.toggleClassName("after-focused", LauncherState.items[focusedID+1] == item);
  });

/**
 * @param {boolean} start
 */
const StackSwitcherPadding = start => Widget.Box({
  class_name: "launcher-switcher-button",
  vexpand: true,
  children: [Widget.Icon()]
})
  .hook(LauncherState, (box) => {
    const focusedID = LauncherState.items.indexOf(LauncherState.value);
    box.toggleClassName("before-focused", start && focusedID === 0);
    box.toggleClassName("after-focused", !start && focusedID === LauncherState.items.length - 1);
  });
/**
 * @param {string[]} items
 */
const StackSwitcher = items => Widget.Box({
  vertical: true,
  class_name: "launcher-switcher",
  children: [
    StackSwitcherPadding(true),
    ...items.map(i => StackSwitcherButton(i)),
    StackSwitcherPadding(false),
  ]
});

const LauncherStack = async () => {
  const children = {
    Search: SearchBox(LauncherState),
    ...Categories(),
  };
  //if(GLib.getenv("XDG_CURRENT_DESKTOP") == "Hyprland") {
  //  children["Hyprland"] = ((await import("./hyprlands.js")).default)(LauncherState);
  //}
  //if (exec("which bt") != "") children["Firefox"] = FirefoxBox(LauncherState);
  //else console.warn("brotab is not installed. Firefox tab switcher module has been disabled.");
  //const stack = Widget.Stack({
  //  visible_child_name: LauncherState.bind(),
  //  transition: "over_right",
  //  class_name: "launcher",
  //  children
  //});
  //return stack;
};


function toggle(value) {
  const current = LauncherState.value;
  if(current == value && App.getWindow("launcher").visible) App.closeWindow("launcher");
  else {
    App.openWindow("launcher");
    LauncherState.value = value;
  }
}

globalThis.toggleLauncher = () => toggle("Search");
//globalThis.toggleHyprlandSwitcher = () => toggle("Hyprland");
//globalThis.toggleFirefoxSwitcher = () => toggle("Firefox");

export default async () => {
  const stack = await LauncherStack();
  LauncherState.items = Object.keys(stack.children);
  const stackSwitcher = StackSwitcher(Object.keys(stack.children));
  const window = Widget.Window({
    keymode: "exclusive",
    visible: false,
    anchor: ["left", "top", "bottom"],
    name: "launcher",
    child: Widget.Box({
      css: "padding-right: 2px",
      children: [
        Widget.Revealer({
          reveal_child: false,
          transition: "slide_right",
          transition_duration: 350,
          child: stackSwitcher,
        }).hook(App, (revealer, name, visible) => {
          if (name === "launcher") {
            if(visible) revealer.reveal_child = visible;
            else timeout(100, () => revealer.reveal_child = visible);
          }
        }),
        Widget.Box({
          children: [
            Widget.Overlay({
              child: Widget.Box({
                children: [
                  Widget.Revealer({
                    reveal_child: false,
                    child: stack,
                    transition_duration: 350,
                    transition: "slide_right"
                  }).hook(App, (revealer, name, visible) => {
                    if (name === "launcher") {
                      if(visible) timeout(100, () => revealer.reveal_child = visible);
                      else revealer.reveal_child = visible;
                    }
                  }),
                  Widget.Box({css: "min-width: 1rem"})
                ]
              }),
              overlays: [
                RoundedCorner("topleft", {class_name: "corner"}),
                RoundedCorner("bottomleft", {class_name: "corner"}),
              ]
            }),
          ]
        })
      ]
    })
  });
  const addKeyBinds = (mods) => {
    window.keybind("Escape", () => App.closeWindow("launcher"));
    window.keybind(mods, "Tab", () => LauncherState.next());
    for (let i = 0; i < 10; i++) {
      window.keybind(mods, `${i}`, () => LauncherState.setIndex(i));
      window.keybind(mods, `KP_${i}`, () => LauncherState.setIndex(i));
    }
  };
  addKeyBinds(["MOD1"]);
  addKeyBinds(["MOD1", "MOD2"]);
  return window;
};

