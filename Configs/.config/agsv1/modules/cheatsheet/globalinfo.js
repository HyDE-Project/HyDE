import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { Box, Label } = Widget;
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
// import { TabContainer } from '../.commonwidgets/tabcontainer.js';
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import Cheat from '../../services/globalinfo.js'
// import name from '../sideleft/tools/name.js';

const CheatItem = (task, id) => {
    const taskName = Widget.Label({
        hexpand: true,
        xalign: 0,
        wrap: true,
        label: task.content,
        selectable: true,
    });
    const actions = Box({
        hpack: 'end',
        children: [
            Widget.Button({ // Remove
                vpack: 'center',
                className: 'txt sidebar-todo-item-action',
                child: MaterialIcon('delete_forever', 'norm', { vpack: 'center' }),
                onClicked: () => {
                    Utils.timeout(200, () => {
                        widgetRevealer.revealChild = false;
                    })
                    Utils.timeout(350, () => {
                        Cheat.remove(id);
                    })
                },
                setup: setupCursorHover,
            }),
        ]
    })
    const cheatContent = Widget.Box({
        className: 'spacing-h-5',
        children: [
            Widget.Box({
                vertical: true,
                children: [
                    actions,
                    taskName,
                ]
            }),
            crosser,
        ]
    });
    const widgetRevealer = Widget.Revealer({
        revealChild: true,
        transition: 'slide_down',
        transitionDuration: userOptions.animations.durationLarge,
        child: cheatContent,
    })
    return Box({
        homogeneous: true,
        children: [widgetRevealer]
    });
}

const cheatItems = () => Widget.Scrollable({
    hscroll: 'never',
    vscroll: 'automatic',
    child: Widget.Box({
        vertical: true,
        className: 'spacing-v-5',
        setup: (self) => self
            .hook(Cheat, (self) => {
                self.children = Cheat.cheat_json.map((task, i) => {
                    return CheatItem(task, i);
                })
                if (self.children.length == 0) {
                    self.homogeneous = true;
                    self.children = [
                        Widget.Box({
                            hexpand: true,
                            vertical: true,
                            vpack: 'center',
                            className: 'txt txt-subtext',
                            children: [
                                MaterialIcon('check_circle', 'hugeass'),
                                Label('Nothing here!')
                            ]
                        })
                    ]
                }
                else self.homogeneous = false;
            }, 'updated')
        ,
    }),
    setup: (listContents) => {
        const vScrollbar = listContents.get_vscrollbar();
        vScrollbar.get_style_context().add_class('sidebar-scrollbar');
    }
});

export default () => Box({
    icon: 'format_list_bulleted',
    name: 'Cheat Sheet',
    children: [
        cheatItems(false),
    ]
})