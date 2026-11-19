import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history from cliphist, newest first, images as thumbnails
Menu {
    id: clipboard
    readonly property string thumbDir: Quickshell.cachePath("clipboard")

    name: "clipboard"

    // cliphist ids restart after "cliphist wipe", so old thumbnails must go
    Component.onCompleted: Quickshell.execDetached(["rm", "-rf", thumbDir])

    // Reload history every time the menu opens
    onOpened: history.running = true

    // Hand the full cliphist line back to cliphist decode, then copy it
    onActivated: item => Quickshell.execDetached(
        ["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", item.line])

    Process {
        id: history
        // Prints the history and decodes images that have no thumbnail file yet
        command: ["sh", "-c", `
            mkdir -p "$1"
            cliphist list | while IFS= read -r line; do
                case "$line" in
                    *"[[ binary data "*)
                        id=$(printf '%s' "$line" | cut -f1)
                        [ -f "$1/$id" ] || printf '%s' "$line" | cliphist decode > "$1/$id"
                        ;;
                esac
                printf '%s\\n' "$line"
            done
        `, "sh", clipboard.thumbDir]

        stdout: StdioCollector {
            // cliphist line format: "<id>\t<preview>"
            onStreamFinished: clipboard.items = text.split("\n")
                .filter(l => l.length > 0)
                .map(l => {
                    const id = l.slice(0, l.indexOf("\t"));
                    const label = l.slice(l.indexOf("\t") + 1);
                    const isImage = label.startsWith("[[ binary data ");
                    return {
                        label: label,
                        line: l,
                        image: isImage ? clipboard.thumbDir + "/" + id : ""
                    };
                })
        }
    }
}
