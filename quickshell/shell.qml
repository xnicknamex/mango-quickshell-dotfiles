import Quickshell

ShellRoot {
    Audio {
        id: audioControl
    }

    Media {
        id: mediaControl
    }

    NetworkMenu {
        id: networkControl
    }

    BluetoothMenu {
        id: bluetoothControl
    }

    ScreenFrame {}

    Bar {
        audio: audioControl
        media: mediaControl
        networkMenu: networkControl
        bluetoothMenu: bluetoothControl
    }

    Launcher {
        id: launcherMenu
    }

    Dock {
        launcher: launcherMenu
    }

    Clipboard {}
    FileSearch {}
    Notifications {}
}
