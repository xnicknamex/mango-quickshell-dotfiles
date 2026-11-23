import QtQuick
import Quickshell
import Quickshell.Io

// Date and time in the bar center ("2026-11-19 14:05").
// Left click opens Merkuro. Right click opens a month calendar attached to the
// screen frame: ‹ › jump one month, today is highlighted, names follow the system
// locale, days with entries are bold. Hovering a day lists its entries below the
// grid (no hover: today, if shown); clicking a day opens Merkuro (it has no way to
// open at a given date). It always opens at the current month.
// Entries come from konsolekalendar (Akonadi), reloaded on every open and month change.
BarIcon {
    id: clock
    readonly property var locale: Qt.locale()
    readonly property date now: time.date

    // Month shown in the calendar (month 0-11)
    property int year: now.getFullYear()
    property int month: now.getMonth()

    // Day numbers of the shown month, 0 = empty cell before the 1st
    readonly property var cells: {
        const offset = (new Date(year, month, 1).getDay() - locale.firstDayOfWeek + 7) % 7;
        const days = new Date(year, month + 1, 0).getDate();
        return Array(offset).fill(0).concat(Array.from({ length: days }, (_, i) => i + 1));
    }

    // Entries of the shown month: { "2026-11-20": [{ start, end, summary }] }
    property var events: ({})
    // Hovered day of the shown month, 0 = none
    property int hoveredDay: 0
    readonly property bool showsCurrentMonth: year === now.getFullYear() && month === now.getMonth()
    // Day listed below the grid: the hovered one, else today if it is shown
    readonly property int detailDay: hoveredDay > 0 ? hoveredDay : showsCurrentMonth ? now.getDate() : 0

    function key(day) {
        return Qt.formatDate(new Date(year, month, day), "yyyy-MM-dd");
    }

    function openApp() {
        Quickshell.execDetached(["merkuro-calendar"]);
    }

    function load() {
        events = {};
        hoveredDay = 0;
        loader.exec({
            command: ["konsolekalendar", "--view", "--export-type", "csv",
                "--date", key(1), "--end-date", key(new Date(year, month + 1, 0).getDate())],
            // The CSV separator is translatable, keep it ","
            environment: { LANGUAGE: "C" }
        });
    }

    function shiftMonth(delta) {
        const d = new Date(year, month + delta, 1);
        year = d.getFullYear();
        month = d.getMonth();
        load();
    }

    text: Qt.formatDateTime(now, "yyyy-MM-dd HH:mm")

    onClicked: openApp()
    onRightClicked: {
        if (!calendar.visible) {
            year = now.getFullYear();
            month = now.getMonth();
            load();
        }
        calendar.toggle();
    }

    SystemClock {
        id: time
        precision: SystemClock.Minutes
    }

    Process {
        id: loader

        stdout: StdioCollector {
            // One line per entry and day, every field quoted ("" = escaped quote):
            // startdate,starttime,enddate,endtime,summary,location,description,uid
            // starttime is empty for all-day entries. Lines outside the shown month
            // (late output of a replaced run) are dropped.
            onStreamFinished: {
                const prefix = clock.key(1).slice(0, 8);
                const result = {};
                for (const line of text.split("\n")) {
                    const f = (line.match(/"(?:[^"]|"")*"/g) ?? []).map(s => s.slice(1, -1).replace(/""/g, '"'));
                    if (f.length < 5 || !f[0].startsWith(prefix))
                        continue;
                    if (!result[f[0]])
                        result[f[0]] = [];
                    result[f[0]].push({ start: f[1].slice(0, 5), end: f[3].slice(0, 5), summary: f[4] });
                }
                clock.events = result;
            }
        }
    }

    BarPopup {
        id: calendar
        target: clock

        Column {
            padding: 6
            spacing: 4

            // ‹ Month Year ›
            Item {
                width: grid.width
                height: title.implicitHeight

                BarIcon {
                    anchors.left: parent.left
                    highlight: true
                    text: "‹"
                    onClicked: clock.shiftMonth(-1)
                }

                StyledText {
                    id: title
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.bold: true
                    text: clock.locale.standaloneMonthName(clock.month, Locale.LongFormat) + " " + clock.year
                }

                BarIcon {
                    anchors.right: parent.right
                    highlight: true
                    text: "›"
                    onClicked: clock.shiftMonth(1)
                }
            }

            Grid {
                id: grid
                columns: 7

                // Weekday names, cut to 2 letters ("Mo." -> "Mo")
                Repeater {
                    model: 7

                    StyledText {
                        required property int index
                        width: 24
                        horizontalAlignment: Text.AlignHCenter
                        text: clock.locale.dayName((clock.locale.firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                    }
                }

                // Days: hover outlines and lists the entries, click opens Merkuro
                Repeater {
                    model: clock.cells

                    Rectangle {
                        id: cell
                        required property int modelData
                        readonly property bool today: clock.showsCurrentMonth && modelData === clock.now.getDate()

                        width: 24
                        height: 18
                        radius: Theme.hoverRadius
                        color: today ? Theme.turquoise : "black"
                        border.color: today ? "black" : Theme.turquoise
                        border.width: area.containsMouse && modelData > 0 ? 1 : 0

                        StyledText {
                            anchors.centerIn: parent
                            color: cell.today ? "black" : Theme.turquoise
                            font.bold: cell.modelData > 0 && clock.events[clock.key(cell.modelData)] !== undefined
                            text: cell.modelData > 0 ? cell.modelData : ""
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: cell.modelData > 0
                            onEntered: clock.hoveredDay = cell.modelData
                            onExited: if (clock.hoveredDay === cell.modelData) clock.hoveredDay = 0
                            onClicked: {
                                calendar.visible = false;
                                clock.openApp();
                            }
                        }
                    }
                }
            }

            // Entries of the hovered day (or today)
            Column {
                visible: clock.detailDay > 0
                width: grid.width
                topPadding: 4

                StyledText {
                    width: parent.width
                    wrapMode: Text.Wrap
                    font.bold: true
                    text: new Date(clock.year, clock.month, clock.detailDay).toLocaleDateString(clock.locale, Locale.LongFormat)
                }

                StyledText {
                    visible: (clock.events[clock.key(clock.detailDay)] ?? []).length === 0
                    text: "No entries"
                }

                Repeater {
                    model: clock.events[clock.key(clock.detailDay)] ?? []

                    StyledText {
                        required property var modelData
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: (modelData.start ? modelData.start + "–" + modelData.end : "All day") + "  " + modelData.summary
                    }
                }
            }
        }
    }
}
