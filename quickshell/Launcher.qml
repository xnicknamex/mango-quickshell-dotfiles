import QtQuick
import Quickshell

// App launcher, alphabetical.
// pick(): opens the same list, but selecting an app emits picked(id) instead of
// starting it; pickFinished() follows when the launcher closes (picked or cancelled).
Menu {
    id: launcher
    readonly property string terminal: "ghostty"
    property bool picking: false

    signal picked(string id)
    signal pickFinished()

    // Also used by the dock
    function launch(entry) {
        // Quickshell's execute() ignores Terminal=true, so wrap those in Ghostty
        if (entry.runInTerminal) {
            Quickshell.execDetached({
                command: [terminal, "-e", ...entry.command],
                workingDirectory: entry.workingDirectory
            });
        } else {
            entry.execute();
        }
    }

    function pick() {
        picking = true;
        show();
    }

    name: "launcher"
    items: [...DesktopEntries.applications.values]
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(e => ({ label: e.name, entry: e }))

    onActivated: item => picking ? picked(item.entry.id) : launch(item.entry)

    onOpenChanged: {
        if (!open && picking) {
            picking = false;
            pickFinished();
        }
    }
}
