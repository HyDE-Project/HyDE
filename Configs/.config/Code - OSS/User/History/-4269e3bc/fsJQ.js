#!/usr/bin/ags -c
import GLib from "gi://GLib";
import "./modules/widgets/widgets.js";
import {exec, idle, monitorFile} from "resource:///com/github/Aylur/ags/utils.js";
import "./utils.js";
import Bar from "./modules/bar/index.js";
import {
  CornerTopleft,
  CornerTopright,
  CornerBottomright,
  CornerBottomleft
} from "./modules/roundedCorner/index.js";
import Quicksettings from "./modules/quicksettings/index.js";
import Launcher from "./modules/applauncher/index.js";
import App from "resource:///com/github/Aylur/ags/app.js";
import Gio from "gi://Gio";
import Gdk from "gi://Gdk";

/**
 * @param {import('types/@girs/gtk-3.0/gtk-3.0').Gtk.Window[]} windows
  */
function addWindows(windows) {
  windows.forEach(win => App.addWindow(win));
}

globalThis.monitorCounter = 0;

globalThis.toggleBars = () => {
  App.windows.forEach(win => {
    if(win.name?.startsWith("bar")) {
      App.toggleWindow(win.name);
    }
  });
};

function addMonitorWindows(monitor) {
  addWindows([
    Bar(monitor),
    CornerTopleft(monitor),
    CornerTopright(monitor),
    CornerBottomleft(monitor),
    CornerBottomright(monitor),
  ]);
  monitorCounter++;
}

idle(async () => {
  addWindows([
    Quicksettings(),
    await Launcher(),
  ]);

  const display = Gdk.Display.get_default();
  for (let m = 0;  m < display?.get_n_monitors();  m++) {
    const monitor = display?.get_monitor(m);
    addMonitorWindows(monitor);
  }

  display?.connect("monitor-added", (disp, monitor) => {
    addMonitorWindows(monitor);
  });

  display?.connect("monitor-removed", (disp, monitor) => {
    App.windows.forEach(win => {
      if(win.gdkmonitor === monitor) App.removeWindow(win);
    });
  });


});


App.config({
  style: "./style.css",
  icons: "./modules/icons",
  closeWindowDelay: {
    quicksettings: 500,
  },
});

