import QtQuick
import Quickshell
import Quickshell.WindowManager
import Quickshell.Services.UPower

// One bar per monitor
Variants {
    id: root
    required property Audio audio
    required property Media media
    required property NetworkMenu networkMenu
    required property BluetoothMenu bluetoothMenu

    // The laptop battery itself (the display device has no health info)
    readonly property UPowerDevice battery: [...UPower.devices.values].find(d => d.isLaptopBattery) ?? UPower.displayDevice
    readonly property var batteryIcons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]

    function duration(seconds) {
        return `${Math.floor(seconds / 3600)} h ${Math.floor(seconds % 3600 / 60)} min`;
    }

    // Same as waybar: "{capacity}%\n{timeTo}\nHealth: {health}%"
    function batteryTooltip() {
        const b = battery;
        let timeTo = "";
        if (b.state === UPowerDeviceState.Charging && b.timeToFull > 0)
            timeTo = "Time to full: " + duration(b.timeToFull);
        else if (b.state === UPowerDeviceState.Discharging && b.timeToEmpty > 0)
            timeTo = "Time to empty: " + duration(b.timeToEmpty);
        const lines = [Math.round(b.percentage * 100) + "%", timeTo];
        if (b.healthSupported)
            lines.push("Health: " + Math.round(b.healthPercentage) + "%");
        return lines.filter(l => l !== "").join("\n");
    }

    model: Quickshell.screens

    PanelWindow {
        id: bar
        required property ShellScreen modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: Theme.barHeight
        color: "black"

        // Left: tags, then the media entry
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 3
            spacing: 8

            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    // Mango hides tags that are empty and not focused
                    model: ScriptModel {
                        values: [...WindowManager.screenProjection(bar.modelData).windowsets]
                            .filter(w => w.shouldDisplay)
                    }

                    Rectangle {
                        id: tag
                        required property Windowset modelData
                        property bool blinkOn: false

                        width: 24
                        height: 14
                        radius: height / 2
                        color: mouse.containsMouse ? Theme.turquoise : "black"
                        border.color: Theme.turquoise
                        border.width: modelData.active || (modelData.urgent && blinkOn) ? 1 : 0

                        // Blink only for urgent tags that are not focused
                        Timer {
                            interval: 500
                            repeat: true
                            running: tag.modelData.urgent && !tag.modelData.active
                            onTriggered: tag.blinkOn = !tag.blinkOn
                            onRunningChanged: if (!running) tag.blinkOn = false
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: tag.modelData.name
                            color: mouse.containsMouse ? "black" : Theme.turquoise
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: tag.modelData.activate()
                        }
                    }
                }
            }

            // Media: controlled player; left click play/pause, right click chooser
            BarIcon {
                id: mediaEntry
                anchors.verticalCenter: parent.verticalCenter
                visible: root.media.player !== null
                width: Math.min(implicitWidth, 300)
                elide: Text.ElideRight
                text: root.media.title(root.media.player)
                // All players, ● = controlled; no tooltip while the popup is open
                tooltip: mediaPopup.visible ? "" : root.media.players
                    .map(p => (p === root.media.player ? "● " : "  ") + root.media.describe(p))
                    .join("\n")
                onClicked: root.media.playPause(root.media.player)
                onRightClicked: mediaPopup.toggle()
            }
        }

        // Center: date and time, right click opens the calendar
        Clock {
            anchors.centerIn: parent
        }

        // Status, right (in reading order: tray, bluetooth, network, mic, speaker, slider, battery)
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            rightPadding: 3
            spacing: 8

            Tray {
                anchors.verticalCenter: parent.verticalCenter
            }

            BluetoothIcon {
                menu: root.bluetoothMenu
            }

            NetworkIcon {
                menu: root.networkMenu
            }

            BarIcon {
                id: micIcon
                text: root.audio.micMuted ? "󰍭" : "󰍬"
                // No tooltip while the popup is open
                tooltip: inputPopup.visible ? "" : root.audio.sourceTooltip
                onClicked: root.audio.toggleMicMute()
                onRightClicked: inputPopup.toggle()
            }

            BarIcon {
                id: speakerIcon
                text: root.audio.muted ? "󰖁" : "󰕾"
                tooltip: outputPopup.visible ? "" : root.audio.sinkTooltip
                onClicked: root.audio.toggleMute()
                onRightClicked: outputPopup.toggle()
            }

            VolumeSlider {
                id: slider
                anchors.verticalCenter: parent.verticalCenter
                value: root.audio.volume
                onMoved: newValue => root.audio.setVolume(newValue)
                onRightClicked: outputPopup.toggle()

                Tooltip {
                    target: slider
                    text: outputPopup.visible ? "" : root.audio.sinkTooltip
                    shown: slider.hovered
                }
            }

            BarIcon {
                text: root.batteryIcons[Math.min(9, Math.floor(root.battery.percentage * 10))]
                    + (UPower.onBattery ? "" : "󱐋")
                tooltip: root.batteryTooltip()
            }
        }

        MediaPopup {
            id: mediaPopup
            target: mediaEntry
            media: root.media
        }

        AudioPopup {
            id: outputPopup
            target: speakerIcon
            sinks: true
        }

        AudioPopup {
            id: inputPopup
            target: micIcon
            sinks: false
        }
    }
}
