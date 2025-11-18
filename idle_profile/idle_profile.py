#!/usr/bin/python3
# coding=utf-8


from dasbus.loop import EventLoop
from dasbus.connection import SessionMessageBus
import subprocess
from gi.repository import GLib
from datetime import datetime

IDLE_TIME_THRESHOLD = 31 * 60 * 1000  # 31 minutes in seconds
CHECK_INTERVAL = 5  # Check every 60 seconds


def run_command(command):
    subprocess.run(command, shell=True, check=True)


def set_low_power():
    run_command("/usr/local/bin/power_profile low-power")


def set_performance():
    run_command("/usr/local/bin/power_profile performance")


def log_message(message):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {message}")


class IdleMonitor:
    def __init__(self):
        self.bus = SessionMessageBus()
        self.screensaver_proxy = self.bus.get_proxy(
            "org.freedesktop.ScreenSaver",
            "/org/freedesktop/ScreenSaver"
        )
        self.is_idle = False

    def check_idle_time(self):
        idle_time = self.screensaver_proxy.GetSessionIdleTime()
        # log_message(f"checking idle time {idle_time}")
        if idle_time >= IDLE_TIME_THRESHOLD and not self.is_idle:
            # log_message("System is idle. Setting low-power profile.")
            set_low_power()
            self.is_idle = True
        elif idle_time < IDLE_TIME_THRESHOLD and self.is_idle:
            # log_message("System is active. Setting performance profile.")
            set_performance()
            self.is_idle = False
        return True


def main():
    loop = EventLoop()
    monitor = IdleMonitor()

    log_message("Power Profile Manager started.")
    GLib.timeout_add_seconds(CHECK_INTERVAL, monitor.check_idle_time)

    loop.run()


if __name__ == "__main__":
    main()
