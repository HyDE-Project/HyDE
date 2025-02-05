const { Gtk, GLib } = imports.gi;
import App from "resource:///com/github/Aylur/ags/app.js";
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
const { EventBox, Button } = Widget;

import Hyprland from "resource:///com/github/Aylur/ags/service/hyprland.js";
import Applications from "resource:///com/github/Aylur/ags/service/applications.js";
const { execAsync, exec } = Utils;
const { Box, Revealer } = Widget;
import { setupCursorHover } from "../.widgetutils/cursorhover.js";
import { getAllFiles, searchIcons } from "./icons.js";
import { MaterialIcon } from "../.commonwidgets/materialicon.js";
import { substitute } from "../.miscutils/icons.js";

const icon_files = userOptions.icons.searchPaths
  .map((e) => getAllFiles(e))
  .flat(1);

let isPinned = false;
let cachePath = new Map();

let timers = [];

function clearTimes() {
  timers.forEach((e) => GLib.source_remove(e));
  timers = [];
}

function ExclusiveWindow(client) {
  const fn = [
    (client) => !(client !== null && client !== undefined),
    // Jetbrains
    (client) => client.title.includes("win"),
    // Vscode
    (client) => client.title === "" && client.class === "",
  ];

  for (const item of fn) {
    if (item(client)) {
      return true;
    }
  }
  return false;
}

const focus = ({ address }) =>
  Utils.execAsync(`hyprctl dispatch focuswindow address:${address}`).catch(
    print,
  );

const DockSeparator = (props = {}) =>
  Box({
    ...props,
    className: "dock-separator",
  });

// const PinButton = () => Widget.Button({
//     className: 'dock-app-btn dock-app-btn-animate',
//     tooltipText: 'Pin Dock',
//     child: Widget.Box({
//         homogeneous: true,
//         className: 'dock-app-icon txt',
//         child: MaterialIcon('push_pin', 'hugeass')
//     }),
//     onClicked: (self) => {
//         isPinned = !isPinned
//         self.className = `${isPinned ? "pinned-dock-app-btn" : "dock-app-btn animate"} dock-app-btn-animate`
//     },
//     setup: setupCursorHover,
// })

const LauncherButton = () =>
  Widget.Button({
    className: "dock-app-btn dock-app-btn-animate",
    tooltipText: "Open launcher",
    child: Widget.Box({
      homogeneous: true,
      className: "dock-app-icon txt",
      child: MaterialIcon("apps", "hugerass"),
    }),
    onClicked: (self) => {
      App.toggleWindow("overview");
    },
    setup: setupCursorHover,
  });

const AppButton = ({ icon, ...rest }) =>
  Widget.Revealer({
    attribute: {
      workspace: 0,
    },
    revealChild: false,
    transition: "slide_right",
    transitionDuration: userOptions.animations.durationLarge,
    child: Widget.Button({
      ...rest,
      className: "dock-app-btn dock-app-btn-animate",
      child: Widget.Box({
        child: Widget.Overlay({
          child: Widget.Box({
            homogeneous: true,
            className: "dock-app-icon",
            child: Widget.Icon({
              icon: icon,
            }),
          }),
          overlays: [
            Widget.Box({
              class_name: "indicator",
              vpack: "end",
              hpack: "center",
            }),
          ],
        }),
      }),
      setup: (button) => {
        setupCursorHover(button);
      },
      onScrollDown: (self) => handleScroll(self, "down"),
      onScrollUp: (self) => handleScroll(self, "up"),
    }),
  });

function handleScroll(button, direction) {
  const term = button.tooltipText.split(" ")[0].toLowerCase(); // Extract the app class from the tooltip
  const clients = Hyprland.clients.filter((client) =>
    client.class.toLowerCase().includes(term),
  );
  if (clients.length > 1) {
    const currentIndex = clients.findIndex(
      (client) => client.address === Hyprland.active.client.address,
    );
    const nextIndex =
      direction === "down"
        ? (currentIndex + 1) % clients.length
        : (currentIndex - 1 + clients.length) % clients.length;
    focus(clients[nextIndex]);
  }
}

let preventAutoHide = false;

const Taskbar = (monitor) =>
  Widget.Box({
    className: "dock-apps",
    attribute: {
      monitor: monitor,
      map: new Map(),
      clientSortFunc: (a, b) => {
        return a.attribute.workspace > b.attribute.workspace;
      },
      update: (box, monitor) => {
        for (let i = 0; i < Hyprland.clients.length; i++) {
          const client = Hyprland.clients[i];
          if (client["pid"] == -1) return;
          const appClass = substitute(client.class);
          // Check if the app is pinned
          if (
            userOptions.dock.pinnedApps.some((appName) =>
              appClass.toLowerCase().includes(appName.toLowerCase()),
            )
          ) {
            continue;
          }
          let appClassLower = appClass.toLowerCase();
          let path = "";
          if (cachePath[appClassLower]) {
            path = cachePath[appClassLower];
          } else {
            path = searchIcons(appClass.toLowerCase(), icon_files);
            cachePath[appClassLower] = path;
          }
          if (path === "") {
            path = substitute(appClass);
          }
          const newButton = EventBox({
            child: AppButton({
              icon: path,
              tooltipText: `${client.title} (${appClass})`,
              onClicked: () => focus(client),
            }),
            setup: (self) => {
              let holdTimeout;
              self.on("button-press-event", (widget, event) => {
                if (event.get_button()[1] === 3) {
                  holdTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
                    preventAutoHide = true;
                    Hyprland.messageAsync(`dispatch closewindow address:${client.address}`).catch(print);
                    return GLib.SOURCE_REMOVE;
                  });
                }
              });
              self.on("button-release-event", (widget, event) => {
                if (event.get_button()[1] === 3 && holdTimeout) {
                  GLib.source_remove(holdTimeout);
                  preventAutoHide = false;
                }
              });
            },
          });
          newButton.child.attribute.workspace = client.workspace.id;
          newButton.child.revealChild = true;
          box.attribute.map.set(client.address, newButton);
        }
        box.children = Array.from(box.attribute.map.values());
      },
      add: (box, address, monitor) => {
        if (!address) {
          // First active emit is undefined
          box.attribute.update(box);
          return;
        }
        const newClient = Hyprland.clients.find((client) => {
          return client.address == address;
        });
        if (ExclusiveWindow(newClient)) {
          return;
        }
        let appClass = newClient.class;
        // Check if the app is pinned
        if (
          userOptions.dock.pinnedApps.some((appName) =>
            appClass.toLowerCase().includes(appName.toLowerCase()),
          )
        ) {
          return;
        }
        let appClassLower = appClass.toLowerCase();
        let path = "";
        if (cachePath[appClassLower]) {
          path = cachePath[appClassLower];
        } else {
          path = searchIcons(appClassLower, icon_files);
          cachePath[appClassLower] = path;
        }
        if (path === "") {
          path = substitute(appClass);
        }
        const newButton = EventBox({
          child: AppButton({
            icon: path,
            tooltipText: `${newClient.title} (${appClass})`,
            onClicked: () => focus(newClient),
          }),
          setup: (self) => {
            let holdTimeout;
            self.on("button-press-event", (widget, event) => {
              if (event.get_button()[1] === 3) {
                holdTimeout = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
                  preventAutoHide = true;
                  Hyprland.messageAsync(`dispatch closewindow address:${newClient.address}`).catch(print);
                  return GLib.SOURCE_REMOVE;
                });
              }
            });
            self.on("button-release-event", (widget, event) => {
              if (event.get_button()[1] === 3 && holdTimeout) {
                GLib.source_remove(holdTimeout);
                preventAutoHide = false;
              }
            });
          },
        });
        newButton.child.attribute.workspace = newClient.workspace.id;
        box.attribute.map.set(address, newButton);
        box.children = Array.from(box.attribute.map.values());
        newButton.child.revealChild = true;
      },
      remove: (box, address) => {
        if (!address) return;

        const removedButton = box.attribute.map.get(address);
        if (!removedButton) return;
        removedButton.child.revealChild = false;

        Utils.timeout(userOptions.animations.durationLarge, () => {
          removedButton.destroy();
          box.attribute.map.delete(address);
          box.children = Array.from(box.attribute.map.values());
        });
      },
    },
    setup: (self) => {
      self
        .hook(
          Hyprland,
          (box, address) => box.attribute.add(box, address, self.monitor),
          "client-added",
        )
        .hook(
          Hyprland,
          (box, address) => box.attribute.remove(box, address, self.monitor),
          "client-removed",
        );
      Utils.timeout(100, () => self.attribute.update(self));
    },
  });

const PinnedApps = () =>
  Widget.Box({
    class_name: "dock-apps",
    homogeneous: true,
    children: userOptions.dock.pinnedApps
      .map((term) => ({ app: Applications.query(term)?.[0], term }))
      .filter(({ app }) => app)
      .map(({ app, term = true }) => {
        const newButton = AppButton({
          // different icon, emm...
          icon: userOptions.dock.searchPinnedAppIcons
            ? searchIcons(app.name, icon_files)
            : app.icon_name,
          onClicked: () => {
            for (const client of Hyprland.clients) {
              if (client.class.toLowerCase().includes(term))
                return focus(client);
            }

            app.launch();
          },
          onMiddleClick: () => app.launch(),
          tooltipText: app.name,
          setup: (self) => {
            self.revealChild = true;
            self.hook(
              Hyprland,
              (button) => {
                const running =
                  Hyprland.clients.find((client) =>
                    client.class.toLowerCase().includes(term),
                  ) || false;

                button.toggleClassName("notrunning", !running);
                button.toggleClassName(
                  "focused",
                  Hyprland.active.client.address == running.address,
                );
                button.set_tooltip_text(running ? running.title : app.name);
              },
              "notify::clients",
            );
          },
        });
        newButton.revealChild = true;
        return newButton;
      }),
  });

export default (monitor = 0) => {
  const dockContent = Box({
    className: "dock-bg spacing-h-5",
    children: [
      // PinButton(),
      PinnedApps(),
      DockSeparator(),
      Taskbar(),
      LauncherButton(),
    ],
  });
  const dockRevealer = Revealer({
    attribute: {
      updateShow: (self) => {
        // I only use mouse to resize. I don't care about keyboard resize if that's a thing
        if (userOptions.dock.monitorExclusivity)
          self.revealChild = Hyprland.active.monitor.id === monitor;
        else self.revealChild = true;

        return self.revealChild;
      },
    },
    revealChild: false,
    transition: "slide_up",
    transitionDuration: userOptions.animations.durationLarge,
    child: dockContent,
    setup: (self) => {
      const callback = (self, trigger) => {
        if (!userOptions.dock.trigger.includes(trigger)) return;
        const flag = self.attribute.updateShow(self);

        if (flag) clearTimes();

        const hidden = userOptions.dock.autoHide.find(
          (e) => e["trigger"] === trigger,
        );

        if (hidden) {
          let id = Utils.timeout(hidden.interval, () => {
            if (!isPinned && !preventAutoHide) {
              self.revealChild = false;
            }
            timers = timers.filter((e) => e !== id);
          });
          timers.push(id);
        }
      };

      self
        // .hook(Hyprland, (self) => self.attribute.updateShow(self))
        .hook(Hyprland.active.workspace, (self) =>
          callback(self, "workspace-active"),
        )
        .hook(Hyprland.active.client, (self) => callback(self, "client-active"))
        .hook(
          Hyprland,
          (self) => callback(self, "client-added"),
          "client-added",
        )
        .hook(
          Hyprland,
          (self) => callback(self, "client-removed"),
          "client-removed",
        );
    },
  });
  return EventBox({
    onHover: () => {
      dockRevealer.revealChild = true;
      clearTimes();
    },
    child: Box({
      homogeneous: true,
      css: `min-height: ${userOptions.dock.hiddenThickness}px;`,
      children: [dockRevealer],
    }),
    setup: (self) =>
      self.on("leave-notify-event", () => {
        if (!isPinned) dockRevealer.revealChild = false;
        clearTimes();
      }),
  });
};
