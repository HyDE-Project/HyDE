import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import App from 'resource:///com/github/Aylur/ags/app.js';
import { execAsync, readFile } from 'resource:///com/github/Aylur/ags/utils.js';

import Gtk from 'gi://Gtk';
import Gdk from 'gi://Gdk';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import GdkPixbuf from 'gi://GdkPixbuf';

import { Marked } from '../../node_modules/marked/lib/marked.esm.js';
import { markedHighlight } from '../../node_modules/marked-highlight/src/index.js';
import hljs from '../highlight.js/lib/index.js';

import CodyAIService from './AIService.js';
import Keys from '../../keys2.js';
import { QSState } from '../quicksettings/index.js';
import Menu from '../quicksettings/menu.js';
import { QuickSettingsPage } from '../quicksettings/quicksettings.js';
import icons from '../icons/index.js';
import ConfigService from '../config/index.js';

const { Box, Button, Label, Scrollable, Entry, Icon, Revealer } = Widget;

const SettingsVisible = Variable(false);
const files = new Map();

function sendMessage(textView, filesContainer) {
    const buffer = textView.get_buffer();
    const [start, end] = buffer.get_bounds();
    const text = buffer.get_text(start, end, true);
    if (!text || text.length === 0) return;

    CodyAIService.send(text, Array.from(files.values()));

    buffer.set_text('', -1);
    filesContainer.clear();
}

const FilesContainer = () => {
    // Implement FilesContainer
    return Box({ vertical: true });
};

const TextEntry = (fileContainer) => {
    return Entry({
        hexpand: true,
        placeholder_text: 'Ask Cody...',
        on_accept: (entry) => {
            sendMessage(entry, fileContainer);
        },
    });
};

const SettingsContainer = () => {
    // Implement SettingsContainer
    return Box({ vertical: true });
};

const CodyContainer = () => {
    const fileContainer = FilesContainer();
    const box = Box({
        class_name: 'cody-container',
        vertical: true,
        children: [
            Revealer({
                reveal_child: SettingsVisible.bind(),
                child: SettingsContainer(),
            }),
            Scrollable({
                class_name: 'cody-message-list',
                hscroll: 'never',
                vscroll: 'always',
                vexpand: true,
                child: Box({ vertical: true })
                    .hook(CodyAIService, (box, idx) => {
                        const msg = CodyAIService.messages[idx];
                        if (!msg) return;
                        const msgWidget = Message(msg, box.get_parent());
                        box.add(msgWidget);
                    }, 'newMsg')
                    .hook(CodyAIService, (box) => {
                        box.children = [];
                    }, 'clear'),
            }),
            Box({
                class_name: 'cody-entry-box',
                vertical: true,
                children: [
                    fileContainer,
                    Box({
                        children: [
                            TextEntry(fileContainer),
                            Button({
                                class_name: 'cody-send-button',
                                on_clicked: () => {
                                    // Implement file or code upload
                                },
                                child: Icon('edit-select-all-symbolic'),
                            }),
                            Button({
                                class_name: 'cody-send-button',
                                on_clicked: (btn) => {
                                    const textView = btn.get_parent().children[0];
                                    sendMessage(textView, fileContainer);
                                },
                                child: Label('󰒊'),
                            }),
                        ],
                    }),
                ],
            }),
        ],
    });
    return box;
};

const Message = (msg, parent) => {
    // Implement Message component
    return Box({ vertical: true });
};

const QSCodyAI = () => QuickSettingsPage(
    Menu({
        title: 'Cody AI',
        icon: icons.ai,
        content: CodyContainer(),
        headerChild: Box({
            class_name: 'spacing-5',
            children: [
                Button({
                    on_clicked: () => CodyAIService.clear(),
                    child: Box({
                        children: [
                            Label('Clear '),
                            Icon(icons.trash.empty),
                        ],
                    }),
                }),
                Button({
                    on_clicked: () => SettingsVisible.value = !SettingsVisible.value,
                    child: Icon(icons.settings),
                }),
            ],
        }),
    })
);

export default CodyContainer;
export { CodyContainer, QSCodyAI };
