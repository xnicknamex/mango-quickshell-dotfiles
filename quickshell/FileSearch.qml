import QtQuick
import Quickshell
import Quickshell.Io

// Fast file search in $HOME and on mounted drives, opens with xdg-open
Menu {
    id: files
    name: "files"
    // Keep the filename visible, cut the path on the left
    elide: Text.ElideLeft

    // Rescan every time the menu opens
    onOpened: scan.running = true

    onActivated: item => Quickshell.execDetached(["xdg-open", item.label])

    Process {
        id: scan
        command: ["fd", ".", Quickshell.env("HOME"), "/run/media"]
        stdout: StdioCollector {
            onStreamFinished: files.items = text.split("\n")
                .filter(l => l.length > 0)
                .map(l => ({ label: l }))
        }
    }
}
