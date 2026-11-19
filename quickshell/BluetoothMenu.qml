import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth modal (right click on the bluetooth icon), built on Menu.qml. All native.
// Order: power, discoverable, paired, new named, new nameless (by address).
// Click: connected -> disconnect, paired -> connect, new -> pair, trust, connect.
// Paired devices have an inline forget glyph.
Menu {
    id: bt
    name: "bluetooth"
    closeOnSelect: false

    // Device of the running connect/pair attempt
    property BluetoothDevice pending: null
    // "connect" or "pair"
    property string pendingAction: ""

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.enabled ? [...adapter.devices.values] : []
    readonly property var pairedDevices: devices.filter(d => d.paired).sort(byName)
    readonly property var newNamed: devices.filter(d => !d.paired && hasName(d)).sort(byName)
    readonly property var newNameless: devices.filter(d => !d.paired && !hasName(d))
        .sort((a, b) => a.address.localeCompare(b.address))

    // deviceName is what the device reports itself; empty for anonymous devices
    function hasName(d) {
        return d.deviceName !== "";
    }

    function byName(a, b) {
        return a.name.localeCompare(b.name);
    }

    // BlueZ icon names -> Nerd Font glyphs
    function glyph(d) {
        const icons = {
            "audio-headset": "󰋋",
            "audio-headphones": "󰋋",
            "audio-card": "󰓃",
            "input-mouse": "󰍽",
            "input-keyboard": "󰌌",
            "input-gaming": "󰊴",
            "phone": "󰏲",
            "computer": "󰟀"
        };
        return icons[d.icon] ?? "󰂯";
    }

    function busy(d) {
        return d.pairing
            || d.state === BluetoothDeviceState.Connecting
            || d.state === BluetoothDeviceState.Disconnecting;
    }

    function label(d) {
        return (d.connected ? "● " : "  ")
            + glyph(d) + " "
            + (hasName(d) ? d.name : d.address)
            + (d.batteryAvailable ? "  " + Math.round(d.battery * 100) + "%" : "")
            + (busy(d) ? "  …" : "");
    }

    function deviceItem(d) {
        return { label: label(d), action: "device", device: d, secondary: d.paired ? "󰆴" : "" };
    }

    items: adapter ? [
        { label: "Bluetooth: " + (adapter.enabled ? "on" : "off"), action: "power" },
        { label: "Discoverable: " + (adapter.discoverable ? "on" : "off"), action: "discoverable" },
        ...pairedDevices.map(deviceItem),
        ...newNamed.map(deviceItem),
        ...newNameless.map(deviceItem)
    ] : []

    function start(d, action) {
        pending = d;
        pendingAction = action;
        if (action === "pair") {
            message = "Pairing with " + (hasName(d) ? d.name : d.address) + "…";
            d.pair();
        } else {
            message = "Connecting to " + (hasName(d) ? d.name : d.address) + "…";
            d.connect();
        }
    }

    function clickDevice(d) {
        if (d.connected) {
            d.disconnect();
            hide();
        } else if (d.paired) {
            start(d, "connect");
        } else {
            start(d, "pair");
        }
    }

    // Scan only while the modal is open (and the adapter is on)
    function updateDiscovery() {
        if (adapter && adapter.enabled)
            adapter.discovering = open;
    }

    onOpenChanged: updateDiscovery()

    Connections {
        target: bt.adapter
        function onEnabledChanged() {
            bt.updateDiscovery();
        }
    }

    onActivated: item => {
        switch (item.action) {
        case "power":
            adapter.enabled = !adapter.enabled;
            break;
        case "discoverable":
            adapter.discoverable = !adapter.discoverable;
            break;
        case "device":
            clickDevice(item.device);
            break;
        }
    }

    onSecondaryActivated: item => {
        if (item.action === "device")
            item.device.forget();
    }

    // Quickshell reports no failure reasons for bluetooth, so failures are
    // detected by the device falling back without success
    Connections {
        target: bt.pending

        function onPairingChanged() {
            const d = bt.pending;
            if (!d || bt.pendingAction !== "pair" || d.pairing)
                return;
            if (d.paired) {
                // Trusted devices may reconnect on their own later
                d.trusted = true;
                bt.start(d, "connect");
            } else {
                bt.message = "Pairing failed: the device may need a PIN, pair it with bluetoothctl";
                bt.pending = null;
            }
        }

        function onConnectedChanged() {
            if (bt.pending && bt.pending.connected) {
                bt.pending = null;
                bt.hide();
            }
        }

        function onStateChanged() {
            const d = bt.pending;
            if (d && bt.pendingAction === "connect" && d.state === BluetoothDeviceState.Disconnected) {
                bt.message = "Connection failed";
                bt.pending = null;
            }
        }
    }
}
