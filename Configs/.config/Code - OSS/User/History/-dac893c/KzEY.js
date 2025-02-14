import Widget from 'resource:///com/github/Aylur/ags/widget.js';

const CodyAI = () => Widget.Box({
    vertical: true,
    children: [
        Widget.Label({
            label: 'Cody AI',
        }),
        Widget.Button({
            label: 'Ask Cody',
            on_clicked: () => {
                // Implementasi fungsi untuk berinteraksi dengan Cody AI
            },
        }),
    ],
});

export default CodyAI;
