//import PopupWindow from '../.widgethacks/popupwindow.js';
//import SidebarLeft from "./sideleft.js";
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box } = Widget;
//import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';

function Bar(monitor = 0) {
    return Widget.Window({
    name: `bar-${monitor}`, // name has to be unique
    anchor: ['left', 'top', 'bottom'],
    name: 'sideleft',
    layer: 'overlay',
    },
}
//    child: Box({
//        children: [
//            SidebarLeft(),
//            clickCloseRegion({ name: 'sideleft', multimonitor: false, fillMonitor: 'horizontal' }),
//        ]
//}
