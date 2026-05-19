pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick

Singleton {
    id: time

    readonly property string time_ss: {
        Qt.formatDateTime(clock.date, "ddd MMM d hh:mm:ss")
    }

    readonly property string time_mm: {
        Qt.formatDateTime(clock.date, "ddd MMM d hh:mm")
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

}
