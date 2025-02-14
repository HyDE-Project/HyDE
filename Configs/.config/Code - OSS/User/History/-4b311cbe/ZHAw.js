import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Scrollable } = Widget;
import QuickScripts from './tools.bak/quickscripts.js';
//import ColorPicker from './tools/colorpicker.js';
import Quote from './tools.bak/quote.js';
import Music from './tools.bak/music.js';
import Name from './tools.bak/name.js';
import Timer from './tools.bak/timer.js';

export default Scrollable({
    hscroll: "never",
    vscroll: "automatic",
    child: Box({
        vertical: true,
        className: 'spacing-v-10',
        children: [
            //ColorPicker(),
            Music(),
            Quote(),
            Timer(),
            // QuickScripts(),
            Box({ vexpand: true }),
            Name(),
        ]
    })
});
