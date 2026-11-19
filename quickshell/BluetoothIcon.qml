import QtQuick
import Quickshell.Bluetooth

// Bluetooth status like waybar: off/blocked 󰂲, on 󰂱, connected .
// Left click toggles adapter power (same as "bluetoothctl power on/off"),
// right click opens the bluetooth modal.
BarIcon {
    id: icon
    property BluetoothMenu menu: null

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool blocked: adapter?.state === BluetoothAdapterState.Blocked
    readonly property var connectedDevices: adapter
        ? [...adapter.devices.values].filter(d => d.connected)
        : []

    // Waybar hides the module without a controller
    visible: adapter !== null

    text: !adapter?.enabled ? "󰂲" : connectedDevices.length > 0 ? "" : "󰂱"

    // "{controller_alias}" + per device "{device_alias}" and "{device_battery_percentage}%"
    tooltip: {
        if (!adapter || blocked)
            return "";
        const lines = [adapter.name];
        for (const d of connectedDevices) {
            lines.push(d.name);
            if (d.batteryAvailable)
                lines.push(Math.round(d.battery * 100) + "%");
        }
        return lines.join("\n");
    }

    onClicked: {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    onRightClicked: {
        if (menu)
            menu.open ? menu.hide() : menu.show();
    }
}
