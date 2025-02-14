import options from 'options';
import brightness from 'services/brightness';
import { OSDLabel } from './label/index';
import { OSDBar } from './bar/index';
import { OSDIcon } from './icon/index';
import { getPosition } from 'lib/utils';
import { Attribute, Child } from 'lib/types/widget';
import { Revealer } from 'resource:///com/github/Aylur/ags/widgets/revealer.js';
import { Window } from 'resource:///com/github/Aylur/ags/widgets/window.js';
const hyprland = await Service.import('hyprland');
const audio = await Service.import('audio');

const { enable, duration, orientation, location, active_monitor, monitor } = options.theme.osd;

const curMonitor = Variable(monitor.value);

hyprland.active.connect('changed', () => {
    curMonitor.value = hyprland.active.monitor.id;
});

let count = 0;

const handleRevealRevealer = (self: Revealer<Child, Attribute>, property: 'reveal_child' | 'visible'): void => {
    if (!enable.value || property !== 'reveal_child') {
        return;
    }

    self.reveal_child = true;

    count++;
    Utils.timeout(duration.value, () => {
        count--;

        if (count === 0) {
            self.reveal_child = false;
        }
    });
};

const handleRevealWindow = (self: Window<Child, Attribute>, property: 'reveal_child' | 'visible'): void => {
    if (!enable.value || property !== 'visible') {
        return;
    }

    self.visible = true;

    count++;
    Utils.timeout(duration.value, () => {
        count--;

        if (count === 0) {
            self.visible = false;
        }
    });
};

const handleReveal = (
    self: Revealer<Child, Attribute> | Window<Child, Attribute>,
    property: 'reveal_child' | 'visible',
): void => {
    if (self instanceof Revealer) {
        handleRevealRevealer(self, property);
    } else if (self instanceof Window) {
        handleRevealWindow(self, property);
    }
};

const renderOSD = (): Revealer<Child, Attribute> => {
    return Widget.Revealer({
        transition: 'crossfade',
        reveal_child: false,
        setup: (self) => {
            self.hook(
                brightness,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::screen',
            );
            self.hook(
                brightness,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::kbd',
            );
            self.hook(
                audio.microphone,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::volume',
            );
            self.hook(
                audio.microphone,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::is-muted',
            );
            self.hook(
                audio.speaker,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::volume',
            );
            self.hook(
                audio.speaker,
                () => {
                    handleReveal(self, 'reveal_child');
                },
                'notify::is-muted',
            );
        },
        child: Widget.Box({
            class_name: 'osd-container',
            vertical: orientation.bind('value').as((ort) => ort === 'vertical'),
            children: orientation.bind('value').as((ort) => {
                if (ort === 'vertical') {
                    return [OSDLabel(), OSDBar(ort), OSDIcon()];
                }

                return [OSDIcon(), OSDBar(ort), OSDLabel()];
            }),
        }),
    });
};

export default (): Window<Child, Attribute> =>
    Widget.Window({
        monitor: Utils.merge(
            [curMonitor.bind('value'), monitor.bind('value'), active_monitor.bind('value')],
            (curMon, mon, activeMonitor) => {
                if (activeMonitor === true) {
                    return curMon;
                }

                return mon;
            },
        ),
        name: `indicator`,
        class_name: 'indicator',
        visible: false,
        layer: options.tear.bind('value').as((tear) => (tear ? 'top' : 'overlay')),
        anchor: location.bind('value').as((v) => getPosition(v)),
        click_through: true,
        child: Widget.Box({
            css: 'padding: 1px;',
            expand: true,
            child: renderOSD(),
        }),
        setup: (self) => {
            self.hook(enable, () => {
                handleReveal(self, 'visible');
            });
            self.hook(
                brightness,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::screen',
            );
            self.hook(
                brightness,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::kbd',
            );
            self.hook(
                audio.microphone,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::volume',
            );
            self.hook(
                audio.microphone,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::is-muted',
            );
            self.hook(
                audio.speaker,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::volume',
            );
            self.hook(
                audio.speaker,
                () => {
                    handleReveal(self, 'visible');
                },
                'notify::is-muted',
            );
        },
    });
