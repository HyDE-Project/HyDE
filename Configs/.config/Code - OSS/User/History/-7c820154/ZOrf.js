import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import App from 'resource:///com/github/Aylur/ags/app.js';
import { execAsync, readFile } from 'resource:///com/github/Aylur/ags/utils.js';
import Gdk from 'gi://Gdk';
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import CodyAIService from './AIService.js';
import { QSState } from '../quicksettings/index.js';
import Menu from '../quicksettings/menu.js';
import { QuickSettingsPage } from '../quicksettings/quicksettings.js';
import icons from '../icons/index.js';

const { Box, Button, Label, Scrollable, Entry, Icon, Revealer } = Widget;

const SettingsVisible = Variable(false);

const sendMessage = (entry, filesContainer) => {
    const text = entry.text;
    if (!text || text.length === 0) return;

    CodyAIService.send(text, filesContainer);
    entry.text = '';
    filesContainer.clear();
};

const FilesContainer = () => Box({ vertical: true });

const TextEntry = (fileContainer) => Entry({
    hexpand: true,
    placeholder_text: 'Ask Cody...',
    on_accept: (entry) => sendMessage(entry, fileContainer),
});

const SettingsContainer = () => Box({
    vertical: true,
    children: [
        Label({ label: 'Cody AI Settings' }),
        // Add more settings widgets as needed
    ],
});

const Message = (msg) => Box({
    vertical: true,
    children: [
        Label({ label: msg.role }),
        Label({ label: msg.content }),
    ],
});

const CodyContainer = () => {
    const fileContainer = FilesContainer();
    return Box({
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
                child: Box({
                    vertical: true,
                    children: CodyAIService.bind('messages').transform(messages =>
                        messages.map(msg => Message(msg))
                    ),
                }),
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
                                class_name: 'cody-upload-button',
                                on_clicked: () => {
                                    // Implement file or code upload
                                },
                                child: Icon('edit-select-all-symbolic'),
                            }),
                            Button({
                                class_name: 'cody-send-button',
                                on_clicked: (btn) => {
                                    const entry = btn.get_parent().get_children()[0];
                                    sendMessage(entry, fileContainer);
                                },
                                child: Icon('send-symbolic'),
                            }),
                        ],
                    }),
                ],
            }),
        ],
    });
};

export const QSCodyAI = () => QuickSettingsPage(
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
                        children: [Label('Clear'), Icon('user-trash-symbolic')],
                    }),
                }),
                Button({
                    on_clicked: () => SettingsVisible.value = !SettingsVisible.value,
                    child: Icon('emblem-system-symbolic'),
                }),
            ],
        }),
    })
);

export default new CodyContainer();
