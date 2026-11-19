import QtQuick
import Quickshell.Io
import Quickshell.Networking

// Network status: ethernet / wifi / wifi off / disconnected (ethernet wins if both).
// Left click toggles the wifi radio, right click opens the network modal.
// Tooltip like waybar:
// wifi "{ipaddr}\n{essid}\n{signalStrength}%\n{frequency}GHz", ethernet "{ipaddr}"
BarIcon {
    id: icon
    property NetworkMenu menu: null

    readonly property var devices: [...Networking.devices.values]
    readonly property NetworkDevice wired: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property NetworkDevice wifi: devices.find(d => d.type === DeviceType.Wifi && d.connected) ?? null
    readonly property NetworkDevice active: wired ?? wifi
    readonly property WifiNetwork wifiNetwork: wifi ? ([...wifi.networks.values].find(n => n.connected) ?? null) : null

    // Not available natively, fetched with nmcli on hover
    property string ip: ""
    property string frequency: ""

    text: wired ? "󰌘" : wifi ? "󰒢" : !Networking.wifiEnabled ? "󰖪" : "󰞃"
    tooltip: {
        if (wired)
            return ip;
        if (wifi)
            return [
                ip,
                wifiNetwork?.name ?? "",
                Math.round((wifiNetwork?.signalStrength ?? 0) * 100) + "%",
                frequency !== "" ? frequency + "GHz" : ""
            ].filter(l => l !== "").join("\n");
        return "";
    }

    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled

    onRightClicked: {
        if (menu)
            menu.open ? menu.hide() : menu.show();
    }

    onHoveredChanged: {
        if (hovered && active)
            details.running = true;
    }

    // Line 1: IPv4 address without prefix, line 2: frequency in MHz (wifi only)
    Process {
        id: details
        command: ["sh", "-c", `
            nmcli -g IP4.ADDRESS device show "$1" | head -n1 | cut -d/ -f1
            nmcli -g IN-USE,FREQ device wifi list ifname "$1" --rescan no 2>/dev/null | grep '^\\*' | cut -d: -f2
        `, "sh", icon.active?.name ?? ""]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                icon.ip = lines[0] ?? "";
                const mhz = parseInt(lines[1] ?? "");
                icon.frequency = isNaN(mhz) ? "" : (mhz / 1000).toFixed(1);
            }
        }
    }
}
