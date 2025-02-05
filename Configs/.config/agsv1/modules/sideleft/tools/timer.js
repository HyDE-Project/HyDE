import Widget from "resource:///com/github/Aylur/ags/widget.js";
import Variable from "resource:///com/github/Aylur/ags/variable.js";
import { MaterialIcon } from "../../.commonwidgets/materialicon.js";
import SidebarModule from "./module.js";

const pausableInterval = (interval, callback) => {
  let source;
  return {
    stop() {
      if (source) {
        source.destroy();
        source = null;
      } else {
        console.warn("already stopped");
      }
    },
    start() {
      if (!source) {
        source = setInterval(callback, interval);
      } else {
        console.warn("already running");
      }
    },
    toggle() {
      if (!source) {
        source = setInterval(callback, interval);
      } else {
        source.destroy();
        source = null;
      }
    },
  };
};

export const TimerSeconds = Variable(0);

const TimerInterval = pausableInterval(1000, () => {
  TimerSeconds.value = TimerSeconds.value + 1;
});

function getCurrentDateTime() {
  const now = new Date();

  const hours = now.getHours().toString().padStart(2, "0");
  const minutes = now.getMinutes().toString().padStart(2, "0");
  const seconds = now.getSeconds().toString().padStart(2, "0");
  const date = now.getDate().toString().padStart(2, "0");
  const month = (now.getMonth() + 1).toString().padStart(2, "0"); // Months are zero-based
  const year = now.getFullYear();

  const formattedDateTime = `${hours}:${minutes}:${seconds}:${date}:${month}:${year}`;
  return formattedDateTime;
}

const convertTime = (seconds) => {
  let hours = Math.floor(seconds / 3600);
  let minutes = Math.floor((seconds % 3600) / 60);
  let remainingSeconds = seconds % 60;

  // Add leading zeros if needed
  hours = hours < 10 ? "0" + hours : hours;
  minutes = minutes < 10 ? "0" + minutes : minutes;
  remainingSeconds =
    remainingSeconds < 10 ? "0" + remainingSeconds : remainingSeconds;

  return { hours, minutes, seconds: String(remainingSeconds) };
};

export default () => {
  return SidebarModule({
    icon: MaterialIcon("timer", "norm"),
    name: "Timer",
    vpack: "center",
    hpack: "center",
    revealChild: false,
    child: Widget.CenterBox({
      vertical: true,
      center_widget: Widget.Box({
        hpack: "center",
        setup: (self) => {
          self.hook(TimerSeconds, (self) => {
            const time = convertTime(TimerSeconds.value);
            self.child = Widget.Label({
              hpack: "fill",
              className: "txt txt-larger timer-label",
              label: `${time.hours}:${time.minutes}:${time.seconds}`,
            });
          });
        },
      }),
      end_widget: Widget.Box({
        hpack: "center",
        vpack: "center",
        className: "spacing-h-10 timer-button-group",
        children: [
          Widget.Button({
            className: "txt-small sidebar-iconbutton timer-button",
            child: MaterialIcon("play_pause", "norm"),
            onClicked: () => {
              TimerInterval.toggle();
            },
          }),
          Widget.Button({
            className: "txt-small sidebar-iconbutton timer-button",
            child: MaterialIcon("restart_alt", "norm"),
            on_clicked: () => {
              TimerInterval.stop();
              TimerSeconds.value = 0;
            },
          }),
        ],
      }),
    }),
  });
};
