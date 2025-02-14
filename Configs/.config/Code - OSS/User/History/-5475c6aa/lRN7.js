import GLib from 'gi://GLib';



const main = '/tmp/ags/hyprpanel/main.js';
const entry = `${App.configDir}/main.ts`;
const bundler = GLib.getenv('AGS_BUNDLER') || 'bun';

const v = {
    ags: pkg.version?.split('.').map(Number) || [],
    expect: [1, 8, 1],
};

try {
    switch (bundler) {
        case 'bun':
            await Utils.execAsync([
                'bun',
                'build',
                entry,
                '--outfile',
                main,
                '--external',
                'resource://*',
                '--external',
                'gi://*',
                '--external',
                'file://*',
            ]);
            break;

        case 'esbuild':
            await Utils.execAsync([
                'esbuild',
                '--bundle',
                entry,
                '--format=esm',
                `--outfile=${main}`,
                '--external:resource://*',
                '--external:gi://*',
                '--external:file://*',
            ]);
            break;

        default:
            throw `"${bundler}" is not a valid bundler`;
    }

    if (v.ags[1] < v.expect[1] || v.ags[2] < v.expect[2]) {
        print(`HyprPanel needs atleast v${v.expect.join('.')} of AGS, yours is v${v.ags.join('.')}`);
        App.quit();
    }

    await import(`file://${main}`);
} catch (error) {
    console.error(error);
    App.quit();
}

import Windows from './end4/config.js';
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

export {};
