import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Scrollable } = Widget;
import QuickScripts from './tools/quickscripts.js';
import ColorPicker from './tools/colorpicker.js';
import Quote from './tools/quote.js';
import Music from './tools/music.js';
import Name from './tools/name.js';
import Timer from './tools/timer.js';

export default Scrollable({
    hscroll: "never",
    vscroll: "automatic",
    child: Box({
        vertical: true,
        className: 'spacing-v-10',
        children: [
            ColorPicker(),
            Music(),
            Quote(),
            Timer(),
            // QuickScripts(),
            Box({ vexpand: true }),
            Name(),
        ]
    })
});
