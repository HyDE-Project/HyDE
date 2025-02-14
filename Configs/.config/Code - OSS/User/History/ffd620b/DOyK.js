const { GLib } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';

import Bluetooth from 'resource:///com/github/Aylur/ags/service/bluetooth.js';
import Network from 'resource:///com/github/Aylur/ags/service/network.js';
const { execAsync, exec } = Utils;
import { BluetoothIndicator, NetworkIndicator } from '../.commonwidgets/statusicons.js';
import { setupCursorHover } from '../.widgetutils/cursorhover.js';
import { MaterialIcon } from '../.commonwidgets/materialicon.js';
import { sidebarOptionsStack } from './sideright.js';

export const ToggleIconWifi = (props = {}) => Widget.Button({
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Wifi | Right-click to configure',
    onClicked: () => Network.toggleWifi(),
    onSecondaryClickRelease: () => {
        execAsync(['bash', '-c', `${userOptions.apps.network}`]).catch(print);
        closeEverything();
    },
    child: NetworkIndicator(),
    setup: (self) => {
        setupCursorHover(self);
        self.hook(Network, button => {
            button.toggleClassName('sidebar-button-active', [Network.wifi?.internet, Network.wired?.internet].includes('connected'))
            button.tooltipText = (`${Network.wifi?.ssid} | Right-click to configure` || 'Unknown');
        });
    },
    ...props,
});

export const ToggleIconBluetooth = (props = {}) => Widget.Button({
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Bluetooth | Right-click to configure',
    onClicked: () => {
        const status = Bluetooth?.enabled;
        if (status)
            exec('rfkill block bluetooth');
        else
            exec('rfkill unblock bluetooth');
    },
    onSecondaryClickRelease: () => {
        execAsync(['bash', '-c', `${userOptions.apps.bluetooth}`]).catch(print);
        closeEverything();
    },
    child: BluetoothIndicator(),
    setup: (self) => {
        setupCursorHover(self);
        self.hook(Bluetooth, button => {
            button.toggleClassName('sidebar-button-active', Bluetooth?.enabled)
        });
    },
    ...props,
});

export const HyprToggleIcon = async (icon, name, hyprlandConfigValue, props = {}) => {
    try {
        return Widget.Button({
            className: 'txt-small sidebar-iconbutton',
            tooltipText: `${name}`,
            onClicked: (button) => {
                // Set the value to 1 - value
                Utils.execAsync(`hyprctl -j getoption ${hyprlandConfigValue}`).then((result) => {
                    const currentOption = JSON.parse(result).int;
                    execAsync(['bash', '-c', `hyprctl keyword ${hyprlandConfigValue} ${1 - currentOption} &`]).catch(print);
                    button.toggleClassName('sidebar-button-active', currentOption == 0);
                }).catch(print);
            },
            child: MaterialIcon(icon, 'norm', { hpack: 'center' }),
            setup: button => {
                button.toggleClassName('sidebar-button-active', JSON.parse(Utils.exec(`hyprctl -j getoption ${hyprlandConfigValue}`)).int == 1);
                setupCursorHover(button);
            },
            ...props,
        })
    } catch {
        return null;
    }
}

export const ModuleNightLight = async (props = {}) => {
    if (!exec(`bash -c 'command -v gammastep'`)) return null;
    return Widget.Button({
        attribute: {
            enabled: false,
        },
        className: 'txt-small sidebar-iconbutton',
        tooltipText: 'Night Light',
        onClicked: (self) => {
            self.attribute.enabled = !self.attribute.enabled;
            self.toggleClassName('sidebar-button-active', self.attribute.enabled);
            if (self.attribute.enabled) Utils.execAsync('gammastep').catch(print)
            else Utils.execAsync('pkill gammastep')
                .then(() => {
                    // disable the button until fully terminated to avoid race
                    self.sensitive = false;
                    const source = setInterval(() => {
                        Utils.execAsync('pkill -0 gammastep')
                            .catch(() => {
                                self.sensitive = true;
                                source.destroy();
                            });
                    }, 500);
                })
                .catch(print);
        },
        child: MaterialIcon('nightlight', 'norm'),
        setup: (self) => {
            setupCursorHover(self);
            self.attribute.enabled = !!exec('pidof gammastep');
            self.toggleClassName('sidebar-button-active', self.attribute.enabled);
        },
        ...props,
    });
}

export const ModuleCloudflareWarp = async (props = {}) => {
    if (!exec(`bash -c 'command -v warp-cli'`)) return null;
    return Widget.Button({
        attribute: {
            enabled: false,
        },
        className: 'txt-small sidebar-iconbutton',
        tooltipText: 'Cloudflare WARP',
        onClicked: (self) => {
            self.attribute.enabled = !self.attribute.enabled;
            self.toggleClassName('sidebar-button-active', self.attribute.enabled);
            if (self.attribute.enabled) Utils.execAsync('warp-cli connect').catch(print)
            else Utils.execAsync('warp-cli disconnect').catch(print);
        },
        child: Widget.Icon({
            icon: 'cloudflare-dns-symbolic',
            className: 'txt-norm',
        }),
        setup: (self) => {
            setupCursorHover(self);
            self.attribute.enabled = !exec(`bash -c 'warp-cli status | grep Disconnected'`);
            self.toggleClassName('sidebar-button-active', self.attribute.enabled);
        },
        ...props,
    });
}

export const ModuleInvertColors = async (props = {}) => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        return Widget.Button({
            className: 'txt-small sidebar-iconbutton',
            tooltipText: 'Color inversion',
            onClicked: (button) => {
                // const shaderPath = JSON.parse(exec('hyprctl -j getoption decoration:screen_shader')).str;
                Hyprland.messageAsync('j/getoption decoration:screen_shader')
                    .then((output) => {
                        const shaderPath = JSON.parse(output)["str"].trim();
                        if (shaderPath != "[[EMPTY]]" && shaderPath != "") {
                            execAsync(['bash', '-c', `hyprctl keyword decoration:screen_shader '[[EMPTY]]'`]).catch(print);
                            button.toggleClassName('sidebar-button-active', false);
                        }
                        else {
                            Hyprland.messageAsync(`j/keyword decoration:screen_shader ${GLib.get_user_config_dir()}/hypr/shaders/invert.frag`)
                                .catch(print);
                            button.toggleClassName('sidebar-button-active', true);
                        }
                    })
            },
            child: MaterialIcon('invert_colors', 'norm'),
            setup: setupCursorHover,
            ...props,
        })
    } catch {
        return null;
    };
}

export const ModuleRawInput = async (props = {}) => {
    try {
        const Hyprland = (await import('resource:///com/github/Aylur/ags/service/hyprland.js')).default;
        return Widget.Button({
            className: 'txt-small sidebar-iconbutton',
            tooltipText: 'Raw input',
            onClicked: (button) => {
                Hyprland.messageAsync('j/getoption input:accel_profile')
                    .then((output) => {
                        const value = JSON.parse(output)["str"].trim();
                        if (value != "[[EMPTY]]" && value != "") {
                            execAsync(['bash', '-c', `hyprctl keyword input:accel_profile '[[EMPTY]]'`]).catch(print);
                            button.toggleClassName('sidebar-button-active', false);
                        }
                        else {
                            Hyprland.messageAsync(`j/keyword input:accel_profile flat`)
                                .catch(print);
                            button.toggleClassName('sidebar-button-active', true);
                        }
                    })
            },
            child: MaterialIcon('mouse', 'norm'),
            setup: setupCursorHover,
            ...props,
        })
    } catch {
        return null;
    };
}

export const ModuleIdleInhibitor = (props = {}) => Widget.Button({ // TODO: Make this work
    attribute: {
        enabled: false,
    },
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Keep system awake',
    onClicked: (self) => {
        self.attribute.enabled = !self.attribute.enabled;
        self.toggleClassName('sidebar-button-active', self.attribute.enabled);
        if (self.attribute.enabled) Utils.execAsync(['bash', '-c', `pidof wayland-idle-inhibitor.py || ${App.configDir}/scripts/wayland-idle-inhibitor.py`]).catch(print)
        else Utils.execAsync('pkill -f wayland-idle-inhibitor.py').catch(print);
    },
    child: MaterialIcon('coffee', 'norm'),
    setup: (self) => {
        setupCursorHover(self);
        self.attribute.enabled = !!exec('pidof wayland-idle-inhibitor.py');
        self.toggleClassName('sidebar-button-active', self.attribute.enabled);
    },
    ...props,
});

export const ModuleReloadIcon = (props = {}) => Widget.Button({
    ...props,
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Reload Environment config',
    onClicked: () => {
        execAsync(['bash', '-c', 'hyprctl reload || swaymsg reload &']);
        App.closeWindow('sideright');
    },
    child: MaterialIcon('refresh', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

export const ModuleSettingsIcon = (props = {}) => Widget.Button({
    ...props,
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Open Settings',
    onClicked: () => {
        execAsync(['bash', '-c', `${userOptions.apps.settings}`, '&']);
        App.closeWindow('sideright');
    },
    child: MaterialIcon('settings', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

export const ModulePowerIcon = (props = {}) => Widget.Button({
    ...props,
    className: 'txt-small sidebar-iconbutton',
    tooltipText: 'Session',
    onClicked: () => {
        closeEverything();
        Utils.timeout(1, () => openWindowOnAllMonitors('session'));
    },
    child: MaterialIcon('power_settings_new', 'norm'),
    setup: button => {
        setupCursorHover(button);
    }
})

// Include the modules.yuck file 
const modules = require('/home/uriel/.config/eww/modules.yuck');

// Define widget transparent
const transparent = Widget.Box({
    orientation: 'vertical',
    spaceEvenly: true,
    className: 'toggle-bar',
    children: [
        Widget.Box({
            spaceEvenly: true,
            orientation: 'vertical',
            spacing: 0,
            children: [
                Widget.EventBox({
                    onHover: 'eww update vertigo_revealnd=true',
                    onHoverLost: 'eww update vertigo_revealnd=false',
                    children: [
                        Widget.Box({
                            spaceEvenly: true,
                            orientation: 'vertical',
                            className: '',
                            children: [
                                // _revealnd widget
                                Widget.Label({
                                    revealon: 'vertigo_revealnd',
                                    config: 'vertigo_config',
                                    className: 'revealnd',
                                }),
                            ],
                        }),
                    ],
                }),
                Widget.EventBox({
                    onHover: 'eww update vertigo_revealex=true',
                    onHoverLost: 'eww open --toggle bar',
                    children: [
                        Widget.Box({
                            spaceEvenly: true,
                            orientation: 'vertical',
                            children: [
                                // _revealex widget
                                Widget.Label({
                                    revealon: 'vertigo_revealex',
                                    className: 'revealex',
                                }),
                            ],
                        }),
                    ],
                }),
            ],
        }),
    ],
});

// Define widget left
const left = Widget.Box({
    className: 'layout-box-transparent',
    orientation: 'vertical',
    spaceEvenly: false,
    halign: 'center',
    spacing: 0,
    children: [
        // button-align widget
        modules.buttonAlign,
    ],
});

// Define widget center
const center = Widget.Box({
    className: 'layout-box-transparent',
    orientation: 'vertical',
    spaceEvenly: false,
    halign: 'center',
    spacing: 30,
    children: [
        // tags widget
        modules.tags,
        Widget.Separator({}),
        // style widget
        modules.style,
    ],
});

// Define widget right
const right = Widget.Box({
    className: 'layout-box transparent',
    orientation: 'vertical',
    spaceEvenly: false,
    halign: 'center',
    spacing: 0,
    children: [
        // _profile widget
        modules._profile,
    ],
});

// Define widget panel
const panel = Widget.Box({
    spacing: '0',
    className: 'background',
    orientation: 'v',
    width: '200',
    height: '500',
    spaceEvenly: 'false',
    children: [
        // _brand widget
        modules._brand,
        Widget.Box({
            valign: 'start',
            orientation: 'horizontal',
            spaceEvenly: false,
            className: 'origin-layout-box',
            children: [
                Widget.Label({
                    halign: 'start',
                    className: 'brand-greet',
                    text: '${hostname}',
                }),
            ],
        }),
        // panel-switch widget
        modules.panelSwitch,
        Widget.Overlay({
            width: '200',
            height: '560',
            children: [
                Widget.Box({
                    className: 's${cPanel}${animatePanel}',
                    children: [
                        // setting-panel widget
                        modules.settingPanel,
                    ],
                }),
                Widget.Box({
                    className: 'c${cPanel}${animatePanel}',
                    children: [
                        // control-panel widget
                        modules.controlPanel,
                    ],
                }),
            ],
        }),
    ],
});

// Define widget control-panel
const controlPanel = Widget.Box({
    orientation: 'vertical',
    className: 'background',
    spaceEvenly: 'false',
    width: '232',
    halign: 'center',
    children: [
        // left-wide widget
        modules.leftWide,
        // center-wide widget
        modules.centerWide,
        // right-wide widget
        modules.rightWide,
    ],
});

// Define widget setting-panel
const settingPanel = Widget.Box({
    width: '200',
    className: 'background-setting-panel',
    orientation: 'v',
    spaceEvenly: 'false',
    children: [
        // _ptime widget
        modules._ptime,
        // _wifi widget
        modules._wifi,
        // controls widget
        modules.controls,
        // _fluidbat widget
        modules._fluidbat,
        // weather widget
        modules.weather,
    ],
});

// Define widget bar-wide
const barWide = Widget.Box({
    className: 'layout-wide-box',
    orientation: 'v',
    spaceEvenly: false,
    children: [
        Widget.Box({
            spaceEvenly: false,
            orientation: 'vertical',
            spacing: 30,
            children: [
                Widget.EventBox({
                    onHover: 'eww update vertigo_revealnd=true',
                    onHoverLost: 'eww update vertigo_revealnd=false',
                    children: [
                        Widget.Box({
                            spaceEvenly: false,
                            orientation: 'vertical',
                            className: '',
                        }),
                    ],
                }),
            ],
        }),
        // left-wide widget
        modules.leftWide,
        // center-wide widget
        modules.centerWide,
        // right-wide widget
        modules.rightWide,
    ],
});

// Define widget left-wide
const leftWide = Widget.Box({
    className: 'left',
    orientation: 'v',
    spaceEvenly: false,
    halign: 'start',
    spacing: 0,
});

// Define widget center-wide
const centerWide = Widget.Box({
    className: 'center',
    orientation: 'v',
    spaceEvenly: false,
    halign: 'start',
    spacing: 0,
    children: [
        // charts2 widget
        modules.charts2,
        // cover widget
        modules.cover,
        // mpd-btn widget
        modules.mpdBtn,
        // _mpdx widget
        modules._mpdx,
        // darktoggle widget
        modules.darktoggle,
    ],
});

// Define widget right-wide
const rightWide = Widget.Box({
    className: 'right',
    orientation: 'v',
    spaceEvenly: false,
    halign: 'start',
    spacing: 0,
    children: [
        // _profilewide widget
        modules._profilewide,
        Widget.Box({
            valign: 'start',
            orientation: 'vertical',
            spaceEvenly: false,
            className: 'origin-layout-box',
            children: [
                Widget.Label({
                    halign: 'center',
                    className: 'origin-greet',
                    text: 'Hey, ${username}.',
                }),
                Widget.Label({
                    halign: 'center',
                    className: 'origin-hostname',
                    text: 'urielzpt@gmail.com',
                }),
            ],
        }),
    ],
});

// Define widget bolt_layout
const boltLayout = Widget.Box({
    spaceEvenly: false,
    className: 'bolt-layout-box',
    spacing: 14,
    orientation: 'vertical',
    children: [
        Widget.Box({
            hexpand: true,
            spaceEvenly: false,
            className: 'bolt-date-bat-pctl',
            spacing: 14,
            children: [
                // charts widget
                modules.charts,
                Widget.Box({
                    orientation: 'vertical',
                    spaceEvenly: false,
                    className: 'bolt-date-bat',
                    spacing: 14,
                    children: [
                        // _boltwifi widget
                        modules._boltwifi,
                        // charts1 widget
                        modules.charts1,
                    ],
                }),
                Widget.Box({
                    orientation: 'horizontal',
                    spaceEvenly: true,
                    className: 'bolt-date-bat',
                    spacing: 14,
                    children: [
                        // sysbuttons widget
                        modules.sysbuttons,
                    ],
                }),
                Widget.Box({
                    orientation: 'horizontal',
                    spaceEvenly: true,
                    className: 'bolt-date-bat',
                    spacing: 14,
                    children: [
                        // music widget
                        modules.music,
                    ],
                }),
                Widget.Box({
                    hexpand: true,
                    spaceEvenly: false,
                    className: 'bolt-uptime-wifi',
                    spacing: 14,
                    children: [
                        // _boltuptime widget
                        modules._boltuptime,
                        // netspeed widget
                        modules.netspeed,
                    ],
                }),
            ],
        }),
    ],
});

// Define window bar
const barWindow = App.Window({
    monitor: 0,
    windowtype: 'dock',
    stacking: 'fg',
    wmIgnore: true,
    geometry: { x: '12px', y: '0px', width: '77px', height: '90%', anchor: 'left center' },
    reserve: { struts: { distance: '4%', side: 'left' } },
    children: [
        // bar widget
        panel,
    ],
});

// Define window bar-wide
const barWideWindow = App.Window({
    stacking: 'bg',
    windowtype: 'dock',
    wmIgnore: true,
    geometry: { x: '12px', y: '0px', width: '130px', height: '90%', anchor: 'left center' },
    reserve: { struts: { distance: '2%', side: 'left' } },
    children: [
        // bar-wide widget
        barWide,
    ],
});

// Define window control-panel
const controlPanelWindow = App.Window({
    monitor: 0,
    wmIgnore: true,
    focusable: 'true',
    geometry: { x: '46', y: '6', height: '90%', width: '150', anchor: 'left center' },
    children: [
        // control-panel widget
        controlPanel,
    ],
});

// Define window setting-panel
const settingPanelWindow = App.Window({
    monitor: 0,
    wmIgnore: true,
    focusable: 'true',
    geometry: { x: '46', y: '6', height: '90%', width: '150', anchor: 'left center' },
    children: [
        // setting-panel widget
        settingPanel,
    ],
});

// Define window panel
const panelWindow = App.Window({
    monitor: 0,
    wmIgnore: true,
    focusable: 'true',
    geometry: { x: '12', y: '0', height: '90%', width: '150', anchor: 'left center' },
    children: [
        // panel widget
        panel,
    ],
});

// Define window transparent
const transparentWindow = App.Window({
    stacking: 'fg',
    windowtype: 'dock',
    wmIgnore: true,
    focusable: 'true',
    geometry: { x: '-7', y: '0', height: '25%', width: '10px', anchor: 'left center' },
    reserve: { struts: { distance: '4%', side: 'left' } },
    children: [
        // transparent widget
        transparent,
    ],
});

// Define window bolt
const boltWindow = App.Window({
    stacking: 'bg',
    windowtype: 'dock',
    wmIgnore: true,
    geometry: { x: 100, y: -35, width: '23%', height: '30%', anchor: 'left bottom' },
    children: [
        // bolt_layout widget
        boltLayout,
    ],
});

// Define variables
const cPanel = 0;
const animatePanel = 0;
const vertigoRevealnd = false;
const vertigoRevealex = false;
const button = './assets/align.png';
const buttonLight = './assets/align-dark.png';
const profile = './assets/uiface2.png';
const download = './assets/Download2.png';
const bg = 'rgba(26, 27, 38, 0.8)';

// Define polls
const vertigoConfigPoll = App.Poll({
    interval: '5000h',
    runWhile: false,
    command: 'cat ewwrc',
});
const usernamePoll = App.Poll({
    interval: '1000s',
    command: 'echo $USER',
});
const hostnamePoll = App.Poll({
    interval: '1000s',
    command: 'hostnamectl hostname',
});
const batteryStatusPoll = App.Poll({
    interval: '1s',
    command: 'cat /sys/class/power_supply/CMB1/device/power_supply/CMB1/status',
});
const batteryPoll = App.Poll({
    interval: '1s',
    command: './scripts/getBattery percent',
});
const networkIconPoll = App.Poll({
    interval: '3s',
    command: './scripts/network.sh icon',
});
const networkClassPoll = App.Poll({
    interval: '3s',
    command: './scripts/network.sh class',
});
const networkNamePoll = App.Poll({
    interval: '3s',
    command: './scripts/network.sh name',
});
const networkStatusPoll = App.Poll({
    interval: '1s',
    command: ' ~/.config/eww/scripts/network.sh status',
});
const networkRadioPoll = App.Poll({
    interval: '1s',
    command: ' ~/.config/eww/scripts/network.sh radio-status',
});
const networkSsidPoll = App.Poll({
    interval: '1s',
    command: ' ~/.config/eww/scripts/network.sh ssid',
});
const volumePoll = App.Poll({
    interval: '1s',
    command: './scripts/getVolume percentage',
});
const isMutedPoll = App.Poll({
    interval: '1s',
    command: ' ~/.config/eww/scripts/volume.sh muted',
});
const redshiftStatePoll = App.Poll({
    interval: '1s',
    command: ' ~/.config/eww/scripts/redshift state',
});
const volumeIconPoll = App.Poll({
    interval: '1s',
    command: './scripts/getVolume icon',
});
const volumeValuePoll = App.Poll({
    interval: '1s',
    command: './scripts/getVolume vol',
});
const mpdProgressPoll = App.Poll({
    interval: '1s',
    command: 'mpc | grep "%)" | awk '{print $4}' | tr -d '(%)' ',
});
const hourPoll = App.Poll({
    interval: '1s',
    command: 'date +%I:%M',
});
const cpuPoll = App.Poll({
    interval: '3s',
    command: './scripts/cpu.sh',
});
const ramPoll = App.Poll({
    interval: '3s',
    command: './scripts/getRam ram',
});
const tempPoll = App.Poll({
    interval: '3s',
    command: './scripts/sysinfo temp',
});
const playerIconPoll = App.Poll({
    interval: '1s',
    command: './scripts/music-info --icon',
});
const playerNamePoll = App.Poll({
    interval: '1s',
    command: './scripts/music-art --player-name',
});
const COVERPoll = App.Poll({
    interval: '1s',
    command: ' ./scripts/music_info --cover',
});
const songPoll = App.Poll({
    interval: '1s',
    command: 'mpc current',
});
const songtimePoll = App.Poll({
    interval: '1s',
    command: './scripts/getSongDuration',
});
const mpdCurrentPoll = App.Poll({
    interval: '1s',
    command: 'mpc | grep "#" | awk '{print $3}' | sed 's|/.*||g' ',
});
const mpdDurationPoll = App.Poll({
    interval: '10s',
    command: 'mpc --format=%time% current',
});
const artistPoll = App.Poll({
    interval: '1s',
    command: 'mpc --format '%artist%' current || true',
});
const playpausePoll = App.Poll({
    interval: '1s',
    command: './scripts/isPlaying',
});
const mpdLevelPoll = App.Poll({
    interval: '0.3s',
    command: 'mpc volume 2>/dev/stdout | awk -F: '{gsub("%| ", "", $2); print $2}' ',
});
const ram2Poll = App.Poll({
    interval: '3s',
    command: './scripts/getRam ram',
});
const weatherPoll = App.Poll({
    interval: '1h',
    command: 'python ~/.config/eww/scripts/weather.py',
});
const weather2Poll = App.Poll({
    interval: '1h',
    command: 'python ~/.config/eww/scripts/weather2.py',
});
const batteryIconPoll = App.Poll({
    interval: '1s',
    command: './scripts/getBattery icon',
});
const datePoll = App.Poll({
    interval: '60s',
    command: 'date "+%H:%M %P"',
});
const calendarDayPoll = App.Poll({
    interval: '10h',
    command: 'date '+%d'',
});
const calendarMonthPoll = App.Poll({
    interval: '10h',
    command: './scripts/getCalendarMonth',
});
const calendarYearPoll = App.Poll({
    interval: '10h',
    command: 'date '+%Y'',
});
const notificationsCardsPoll = App.Listen({
    command: './scripts/logger.zsh subscribe',
});
const notificationsCritsPoll = App.Poll({
    interval: '1s',
    command: './scripts/logger.zsh crits',
});
const notificationNumPoll = App.Poll({
    interval: '1s',
    command: './scripts/logger.zsh tot',
});
const batPoll = App.Poll({
    interval: '10s',
    command: ' ./scrips/getBattery percent',
});
const timePoll = App.Poll({
    interval: '1s',
    command: 'date +'{"hour":"%H","min":"%M","sec":"%S","pretty":"%a, %e %b","day":"%A","month":"%B","dom":"%e","year":"%Y","day_num":"%d","month_num":"%m","year_num":"%y"}'',
});
const uptimePoll = App.Poll({
    interval: '48h',
    command: 'uptime --pretty | ./scripts/uptime.awk',
});
const netPoll = App.Poll({
    interval: '100s',
    command: 'nmcli -terse -fields SIGNAL,ACTIVE device wifi | awk --field-separator ':' '{if($2=="yes")print$1}' ',
});
const ssidPoll = App.Poll({
    interval: '100s',
    command: 'nmcli -terse -fields SSID,ACTIVE device wifi | awk --field-separator ':' '{if($2=="yes")print$1}' ',
});

// Define listens
const tagsListen = App.Listen({
    command: './scripts/getWorkspaces',
});
const tags2Listen = App.Listen({
    command: './scripts/getWorkspaces2',
});
const mpdSubListen = App.Listen({
    command: 'python ./src/shell/mpdaemon.py',
});

// Run the polls and listens
vertigoConfigPoll.start();
usernamePoll.start();
hostnamePoll.start();
batteryStatusPoll.start();
batteryPoll.start();
networkIconPoll.start();
networkClassPoll.start();
networkNamePoll.start();
networkStatusPoll.start();
networkRadioPoll.start();
networkSsidPoll.start();
volumePoll.start();
isMutedPoll.start();
redshiftStatePoll.start();
volumeIconPoll.start();
volumeValuePoll.start();
mpdProgressPoll.start();
hourPoll.start();
cpuPoll.start();
ramPoll.start();
tempPoll.start();
playerIconPoll.start();
playerNamePoll.start();
COVERPoll.start();
songPoll.start();
songtimePoll.start();
mpdCurrentPoll.start();
mpdDurationPoll.start();
artistPoll.start();
playpausePoll.start();
mpdLevelPoll.start();
ram2Poll.start();
weatherPoll.start();
weather2Poll.start();
batteryIconPoll.start();
datePoll.start();
calendarDayPoll.start();
calendarMonthPoll.start();
calendarYearPoll.start();
notificationsCardsPoll.start();
notificationsCritsPoll.start();
notificationNumPoll.start();
batPoll.start();
timePoll.start();
uptimePoll.start();
netPoll.start();
ssidPoll.start();
tagsListen.start();
tags2Listen.start();
mpdSubListen.start();