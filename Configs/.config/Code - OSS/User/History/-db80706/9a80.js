const { Gdk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Button, EventBox, Label, Revealer, Scrollable, Stack } = Widget;
const { execAsync, exec } = Utils;
import { MaterialIcon } from './modules/materialicon.js';
import { setupCursorHover } from './modules/cursorhover.js';
import toolBox from './modules/tools/toolbox.js';
//import apiWidgets from './modules/apiwidgets.js';
//import { chatEntry } from './modules/apiwidgets.js';
//import { TabContainer } from '../.commonwidgets/tabcontainer.js';
//import { checkKeybind } from '../.widgetutils/keybind.js';

