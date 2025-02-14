import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { exec, log } from 'resource:///com/github/Aylur/ags/utils.js';
import CodyCliHandler from './codyCliHandler.js';

const Cody = () => {
    const outputLabel = Widget.Label({
        className: 'cody-output',
        label: 'Cody\'s response will appear here',
        wrap: true,
        use_markup: true,
    });

    return Widget.Box({
        className: 'cody-widget',
        vertical: true,
        children: [
            Widget.Label({
                className: 'cody-title',
                label: 'Cody CLI',
            }),
            Widget.Entry({
                className: 'cody-input',
                hexpand: true,
                placeholder_text: 'Ask Cody...',
                on_accept: ({ text }) => {
                    if (text) {
                        log(`Asking Cody: ${text}`);
                        outputLabel.label = 'Processing...';
                        CodyCliHandler.askCody(text)
                            .then(response => {
                                outputLabel.label = response;
                            })
                            .catch(error => {
                                log(`Error: ${error}`);
                                outputLabel.label = 'An error occurred. Please try again.';
                            });
                    }
                },
            }),
            outputLabel,
        ],
    });
};

export default Cody;
