import QtQuick
import Quickshell

// App launcher, alphabetical
Menu {
    readonly property string terminal: "ghostty"

    name: "launcher"
    items: [...DesktopEntries.applications.values]
        .sort((a, b) => a.name.localeCompare(b.name))
        .map(e => ({ label: e.name, entry: e }))

    onActivated: item => {
        // Quickshell's execute() ignores Terminal=true, so wrap those in Ghostty
        if (item.entry.runInTerminal) {
            Quickshell.execDetached({
                command: [terminal, "-e", ...item.entry.command],
                workingDirectory: item.entry.workingDirectory
            });
        } else {
            item.entry.execute();
        }
    }
}
