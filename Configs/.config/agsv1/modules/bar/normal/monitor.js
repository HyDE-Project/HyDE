const { GLib } = imports.gi;
import Widget from "resource:///com/github/Aylur/ags/widget.js";
import * as Utils from "resource:///com/github/Aylur/ags/utils.js";
const { Box, Button, EventBox, Label, Overlay, Revealer } = Widget;
const { execAsync, exec } = Utils;
import { AnimatedCircProg } from "../../.commonwidgets/cairo_circularprogress.js";
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";

const CUSTOM_MODULE_CONTENT_INTERVAL_FILE = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-interval.txt`;
const CUSTOM_MODULE_CONTENT_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-poll.sh`;
const CUSTOM_MODULE_LEFTCLICK_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-leftclick.sh`;
const CUSTOM_MODULE_RIGHTCLICK_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-rightclick.sh`;
const CUSTOM_MODULE_MIDDLECLICK_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-middleclick.sh`;
const CUSTOM_MODULE_SCROLLUP_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-scrollup.sh`;
const CUSTOM_MODULE_SCROLLDOWN_SCRIPT = `${GLib.get_user_cache_dir()}/ags/user/scripts/custom-module-scrolldown.sh`;

const BarGroup = ({ child }) =>
  Box({
    className: "bar-group-margin bar-sides",
    children: [
      Box({
        className: "bar-group bar-group-standalone bar-group-pad-system",
        children: [child],
      }),
    ],
  });

const BarResource = (
  name,
  icon,
  command,
  circprogClassName = "bar-batt-circprog",
  textClassName = "txt-onSurfaceVariant",
  iconClassName = "bar-batt"
) => {
  const resourceCircProg = AnimatedCircProg({
    className: `${circprogClassName}`,
    vpack: "center",
    hpack: "center",
  });
  const resourceProgress = Box({
    homogeneous: true,
    children: [
      Overlay({
        child: Box({
          vpack: "center",
          className: `${iconClassName}`,
          homogeneous: true,
          children: [MaterialIcon(icon, "small")],
        }),
        overlays: [resourceCircProg],
      }),
    ],
  });
  const resourceLabel = Label({
    className: `txt-smallie ${textClassName}`,
  });
  const widget = Button({
    onClicked: () =>
      Utils.execAsync(["bash", "-c", `${userOptions.apps.taskManager}`]).catch(
        print
      ),
    child: Box({
      className: `spacing-h-4 ${textClassName}`,
      children: [resourceProgress, resourceLabel],
      setup: (self) =>
        self.poll(5000, () =>
          execAsync(["bash", "-c", command])
            .then((output) => {
              resourceCircProg.css = `font-size: ${Number(output)}px;`;
              resourceLabel.label = `${Math.round(Number(output))}%`;
              widget.tooltipText = `${name}: ${Math.round(Number(output))}%`;
            })
            .catch(print)
        ),
    }),
  });
  return widget;
};

const BarResourceTemp = (
  name,
  icon,
  command,
  circprogClassName = "bar-batt-circprog",
  textClassName = "txt-onSurfaceVariant",
  iconClassName = "bar-batt"
) => {
  const resourceCircProg = AnimatedCircProg({
    className: `${circprogClassName}`,
    vpack: "center",
    hpack: "center",
  });
  const resourceProgress = Box({
    homogeneous: true,
    children: [
      Overlay({
        child: Box({
          vpack: "center",
          className: `${iconClassName}`,
          homogeneous: true,
          children: [MaterialIcon(icon, "small")],
        }),
        overlays: [resourceCircProg],
      }),
    ],
  });
  const resourceLabel = Label({
    className: `txt-smallie ${textClassName}`,
  });
  const widget = Button({
    onClicked: () =>
      Utils.execAsync(["bash", "-c", `${userOptions.apps.taskManager}`]).catch(
        print
      ),
    child: Box({
      className: `spacing-h-4 ${textClassName}`,
      children: [resourceProgress, resourceLabel],
      setup: (self) =>
        self.poll(5000, () =>
          execAsync(["bash", "-c", command])
            .then((output) => {
              resourceCircProg.css = `font-size: ${Number(output)}px;`;
              resourceLabel.label = `${Math.round(Number(output))}°C`;
              widget.tooltipText = `${name}: ${Math.round(Number(output))}%`;
            })
            .catch(print)
        ),
    }),
  });
  return widget;
};

const switchToRelativeWorkspace = async (self, num) => {
  try {
    const Hyprland = (
      await import("resource:///com/github/Aylur/ags/service/hyprland.js")
    ).default;
    Hyprland.messageAsync(
      `dispatch workspace ${num > 0 ? "+" : ""}${num}`
    ).catch(print);
  } catch {
    execAsync([
      `${App.configDir}/scripts/sway/swayToRelativeWs.sh`,
      `${num}`,
    ]).catch(print);
  }
};

export default () => {
  const SystemResourcesOrCustomModule = () => {
    if (GLib.file_test(CUSTOM_MODULE_CONTENT_SCRIPT, GLib.FileTest.EXISTS)) {
      const interval =
        Number(Utils.readFile(CUSTOM_MODULE_CONTENT_INTERVAL_FILE)) || 5000;
      return BarGroup({
        child: Button({
          child: Label({
            className: "txt-smallie txt-onSurfaceVariant",
            useMarkup: true,
            setup: (self) =>
              Utils.timeout(1, () => {
                self.label = exec(CUSTOM_MODULE_CONTENT_SCRIPT);
                self.poll(interval, (self) => {
                  const content = exec(CUSTOM_MODULE_CONTENT_SCRIPT);
                  self.label = content;
                });
              }),
          }),
          onPrimaryClickRelease: () =>
            execAsync(CUSTOM_MODULE_LEFTCLICK_SCRIPT).catch(print),
          onSecondaryClickRelease: () =>
            execAsync(CUSTOM_MODULE_RIGHTCLICK_SCRIPT).catch(print),
          onMiddleClickRelease: () =>
            execAsync(CUSTOM_MODULE_MIDDLECLICK_SCRIPT).catch(print),
          onScrollUp: () =>
            execAsync(CUSTOM_MODULE_SCROLLUP_SCRIPT).catch(print),
          onScrollDown: () =>
            execAsync(CUSTOM_MODULE_SCROLLDOWN_SCRIPT).catch(print),
        }),
      });
    } else
      return BarGroup({
        child: Box({
          children: [
            BarResource(
              "RAM Usage",
              "memory_alt",
              `LANG=C free | awk '/^Mem/ {printf("%.2f\\n", ($3/$2) * 100)}'`,
              "bar-ram-circprog",
              "bar-ram-txt",
              "bar-ram-icon"
            ),
            Revealer({
              revealChild: true,
              transition: "slide_left",
              transitionDuration: userOptions.animations.durationLarge,
              child: Box({
                className: "spacing-h-10 margin-left-10",
                children: [
                  BarResource(
                    "CPU Usage",
                    "developer_board",
                    `LANG=C top -bn1 | awk '/^%Cpu/ {printf("%.2f\\n", 100 - $8)}'`,
                    "bar-cpu-circprog",
                    "bar-cpu-txt",
                    "bar-cpu-icon"
                  ),
                ],
              }),
            }),
            Revealer({
              revealChild: true,
              transition: "slide_left",
              transitionDuration: userOptions.animations.durationLarge,
              child: Box({
                className: "spacing-h-10 margin-left-10",
                children: [
                  BarResourceTemp(
                    "CPU Temp",
                    "device_thermostat",
                    `LANG=C sensors | awk '/^Package id 0/ {printf("%.2f\\n", $4)}'`,
                    "bar-cpu-circprog",
                    "bar-cpu-txt",
                    "bar-cpu-icon"
                  ),
                ],
              }),
            }),
          ],
        }),
      });
  };
  return EventBox({
    onScrollUp: (self) => switchToRelativeWorkspace(self, -1),
    onScrollDown: (self) => switchToRelativeWorkspace(self, +1),
    child: Box({
      children: [SystemResourcesOrCustomModule()],
    }),
  });
};
