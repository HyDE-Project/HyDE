/**
 * Creates a PopupWindow with a SidebarLeft component and a clickCloseRegion component.
 *
 * The PopupWindow is configured with the following options:
 * - `keymode`: 'on-demand' - The PopupWindow is only shown when explicitly requested.
 * - `anchor`: ['left', 'top', 'bottom'] - The PopupWindow is anchored to the left side of the screen, and extends from the top to the bottom.
 * - `name`: 'sideleft' - The name of the PopupWindow.
 * - `layer`: 'overlay' - The PopupWindow is displayed as an overlay on top of other content.
 *
 * The PopupWindow contains two child components:
 * - `SidebarLeft`: The main content of the sidebar.
 * - `clickCloseRegion`: A component that allows the user to click outside the sidebar to close it.
 */
import PopupWindow from '../.widgethacks/popupwindow.js';
import SidebarLeft from "./sideleft.js";
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box } = Widget;
import clickCloseRegion from '../.commonwidgets/clickcloseregion.js';

export default () => PopupWindow({
    keymode: 'on-demand',
    anchor: ['left', 'top', 'bottom'],
    name: 'sideleft',
    layer: 'overlay',
    child: Box({
        children: [
            SidebarLeft(),
            clickCloseRegion({ name: 'sideleft', multimonitor: false, fillMonitor: 'horizontal' }),
        ]
    })
});
