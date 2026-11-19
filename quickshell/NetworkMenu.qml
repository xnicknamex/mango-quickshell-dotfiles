import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

// Wifi modal (right click on the network icon), built on Menu.qml.
// Native: list, connect, password connect, disconnect, forget, wifi toggle, scanning.
// nmcli only for hidden networks (Quickshell cannot create new connections).
Menu {
    id: net
    name: "network"
    closeOnSelect: false

    // "" = list, "password" = password for `target`, "ssid" / "hiddenPassword" = hidden network steps
    property string step: ""
    property WifiNetwork target: null
    property WifiNetwork connecting: null
    property string hiddenSsid: ""

    readonly property var signalIcons: ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    readonly property var wifiDevices: [...Networking.devices.values].filter(d => d.type === DeviceType.Wifi)
    // Sorted by signal level (5 steps, so rows don't jump on every scan), then name
    readonly property var networks: wifiDevices
        .flatMap(d => [...d.networks.values])
        .sort((a, b) => level(b) - level(a) || a.name.localeCompare(b.name))

    function level(n) {
        return Math.min(4, Math.floor(n.signalStrength * 5));
    }

    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }

    // Password networks connectWithPsk can handle
    function isPsk(n) {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(n.security);
    }

    function label(n) {
        return (n.connected ? "● " : "  ")
            + signalIcons[level(n)] + " "
            + (isOpen(n) ? "  " : "󰌾 ")
            + n.name
            + (n.stateChanging ? "  …" : "")
            + (!isOpen(n) && !isPsk(n) && !n.known ? "  (not supported)" : "");
    }

    items: [
        { label: "Wifi: " + (Networking.wifiEnabled ? "on" : "off"), action: "wifi" },
        // Saved networks get an inline forget glyph
        ...networks.map(n => ({ label: label(n), action: "network", network: n, secondary: n.known ? "󰆴" : "" })),
        { label: "Hidden network…", action: "hidden" }
    ]

    function connectTo(n, psk) {
        connecting = n;
        message = "Connecting to " + n.name + "…";
        if (psk === null)
            n.connect();
        else
            n.connectWithPsk(psk);
    }

    function askPassword(n, reason) {
        target = n;
        step = "password";
        message = reason;
        ask("Password for " + n.name, true);
    }

    function clickNetwork(n) {
        if (n.connected) {
            n.disconnect();
            hide();
        } else if (n.known || isOpen(n)) {
            connectTo(n, null);
        } else if (isPsk(n)) {
            askPassword(n, "");
        } else {
            message = n.name + ": this security type is not supported";
        }
    }

    onOpened: {
        step = "";
        target = null;
    }

    // Scan only while the modal is open
    onOpenChanged: {
        for (const d of wifiDevices)
            d.scannerEnabled = open;
    }

    onActivated: item => {
        switch (item.action) {
        case "wifi":
            Networking.wifiEnabled = !Networking.wifiEnabled;
            break;
        case "network":
            clickNetwork(item.network);
            break;
        case "hidden":
            step = "ssid";
            message = "";
            ask("Hidden network: SSID", false);
            break;
        }
    }

    onSecondaryActivated: item => {
        if (item.action === "network")
            item.network.forget();
    }

    onSubmitted: text => {
        if (step === "password") {
            const n = target;
            step = "";
            showList();
            connectTo(n, text);
        } else if (step === "ssid") {
            if (text === "")
                return;
            hiddenSsid = text;
            step = "hiddenPassword";
            ask("Password for " + text + " (empty = open)", true);
        } else if (step === "hiddenPassword") {
            step = "";
            showList();
            message = "Connecting to " + hiddenSsid + "…";
            hiddenConnect.command = ["nmcli", "device", "wifi", "connect", hiddenSsid]
                .concat(text !== "" ? ["password", text] : [])
                .concat(["hidden", "yes"]);
            hiddenConnect.running = true;
        }
    }

    onBackRequested: {
        step = "";
        message = "";
        showList();
    }

    // Native result of a connection attempt
    Connections {
        target: net.connecting

        function onConnectedChanged() {
            if (net.connecting && net.connecting.connected) {
                net.connecting = null;
                net.hide();
            }
        }

        function onConnectionFailed(reason) {
            const n = net.connecting;
            net.connecting = null;
            if (reason === ConnectionFailReason.NoSecrets && net.isPsk(n))
                net.askPassword(n, "Wrong or missing password");
            else
                net.message = n.name + ": " + ConnectionFailReason.toString(reason);
        }
    }

    // Hidden networks: not possible natively (no API to create connections)
    Process {
        id: hiddenConnect
        stderr: StdioCollector {
            id: hiddenError
        }
        onExited: exitCode => {
            if (exitCode === 0)
                net.hide();
            else
                net.message = hiddenError.text.trim() || "Connection failed";
        }
    }
}
