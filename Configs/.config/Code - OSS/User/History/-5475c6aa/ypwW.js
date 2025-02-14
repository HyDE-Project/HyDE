"use strict";
// Import
import Gdk from 'gi://Gdk';
import GLib from 'gi://GLib';
import App from 'resource:///com/github/Aylur/ags/app.js'
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js'
// Stuff
import userOptions from './modules/.configuration/user_options.js';
// Widgets Sideleft
import { Bar, BarCornerTopleft, BarCornerTopright } from './modules/bar/main.js';
import SideLeft from './modules/sideleft/main.js';
import { COMPILED_STYLE_DIR } from './init.js';

// Widget Sideright
import SideRight from './modules/sideright/main.js';

// BAR
import Session from './modules/session/main.js';
const range = (length, start = 1) => Array.from({ length }, (_, i) => i + start);
function forMonitors(widget) {
    const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
    return range(n, 0).map(widget).flat(1);
}
function forMonitorsAsync(widget) {
    const n = Gdk.Display.get_default()?.get_n_monitors() || 1;
    return range(n, 0).forEach((n) => widget(n).catch(print))
}



// Start stuff
handleStyles(true);

const Windows = () => [
    SideLeft(),
// siderigt
    SideRight(),
// BAR
    //forMonitors(Session),
    //...(userOptions.appearance.barRoundCorners ? [
    //    forMonitors(BarCornerTopleft),
    //    forMonitors(BarCornerTopright),
    //] : []),
];


//App.config({
//    windows: Windows(),
//});

App.config({
    windows: Windows().flat(1),
});

//forMonitorsAsync(Bar);