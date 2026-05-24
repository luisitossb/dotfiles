import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.CustomTheme

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-settings-app"
    exclusionMode: WlrLayershell.Ignore
    implicitWidth: 720
    implicitHeight: 520
    color: "transparent"

    property bool isOpen: false
    property real panelOpacity: isOpen ? 1.0 : 0.0
    property real panelScale:   isOpen ? 1.0 : 0.95

    Behavior on panelOpacity { NumberAnimation { id: fadeAnim; duration: 250; easing.type: Easing.OutQuint } }
    Behavior on panelScale   { NumberAnimation {               duration: 250; easing.type: Easing.OutQuint } }

    visible: isOpen || fadeAnim.running

    // ── Appearance state ──────────────────────────────────────────────────────

    property int    currentFontIndex: 0
    property string colorMode:        "dark"

    readonly property var fontOptions: ["Press Start 2P", "Orbitron", "Silkscreen"]

    Process {
        id: fontStateProc
        command: ["bash", "-c",
            "cat " + Quickshell.env("HOME") + "/.config/waybar/active-font 2>/dev/null || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.currentFontIndex = parseInt(this.text.trim()) || 0 }
    }
    Process {
        id: colorModeProc
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/settings/color-mode"]
        stdout: StdioCollector { onStreamFinished: root.colorMode = this.text.trim() || "dark" }
    }

    // ── Input state ───────────────────────────────────────────────────────────

    property bool   naturalScroll:  false
    property bool   numlockDefault: true
    property bool   accelEnabled:   false
    property string kbLayout:       "us"

    Process {
        id: inputStateProc
        command: ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/input-state.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                mouseScrollSlider.value = d.ms
                mouseSensSlider.value   = d.msens
                tpadScrollSlider.value  = d.ts
                tpadSensSlider.value    = d.tsens
                root.naturalScroll      = d.nat
                root.numlockDefault     = d.nl
                root.accelEnabled       = d.accel === "adaptive"
                root.kbLayout           = d.kbl
            } catch(e) { console.warn("input-state parse error: " + e) }
        }}
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    onIsOpenChanged: {
        if (isOpen) {
            fontStateProc.running  = false; fontStateProc.running  = true
            colorModeProc.running  = false; colorModeProc.running  = true
            inputStateProc.running = false; inputStateProc.running = true
        }
    }

    HyprlandFocusGrab {
        windows: [root]
        active: root.isOpen
        onCleared: root.isOpen = false
    }

    Shortcut {
        sequence: "Escape"
        onActivated: if (root.isOpen) root.isOpen = false
    }

    IpcHandler {
        target: "settings-app"
        function toggle(): void { root.isOpen = !root.isOpen }
        function open():   void { root.isOpen = true  }
        function close():  void { root.isOpen = false }
    }

    property int selectedCategory: 0

    readonly property var categories: [
        { name: "Appearance",      icon: "󰸌", sections: [] },
        { name: "Input",           icon: "󰍽", sections: [] },
        { name: "Audio & Display", icon: "󰕾", sections: ["Volume", "Brightness", "Night Mode"] },
        { name: "System & Apps",   icon: "󰮤", sections: ["Startup Apps", "Power", "About"] }
    ]

    // ── Shared sub-components ─────────────────────────────────────────────────

    component PlaceholderCard: Rectangle {
        property string title: ""
        Layout.fillWidth: true
        implicitHeight: 60; radius: 12
        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                       Theme.surface_container.b, 1.0)
        border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g,
                              Theme.outline_variant.b, 0.2)
        border.width: 1
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 3
            Text { text: title; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }
            Text { text: "Coming soon..."; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
        }
    }

    component InputSlider: Item {
        id: iSlider
        property real value: 0
        property real from: 0
        property real to: 1
        property real stepSize: 0.05
        signal released(real v)

        implicitHeight: 24
        Layout.fillWidth: true

        property real _pct: to > from ? Math.max(0, Math.min(1, (value - from) / (to - from))) : 0

        Rectangle {
            id: iTrack
            anchors.verticalCenter: parent.verticalCenter
            x: 8; width: parent.width - 16; height: 4; radius: 2
            color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)

            Rectangle {
                width: parent.width * iSlider._pct
                height: parent.height; radius: parent.radius
                color: Theme.primary
            }
        }

        Rectangle {
            anchors.verticalCenter: iTrack.verticalCenter
            x: iTrack.width * iSlider._pct
            width: 16; height: 16; radius: 8
            color: iDrag.pressed
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.7)
                : Theme.primary
            border.color: Qt.rgba(1, 1, 1, 0.3); border.width: 1
            Behavior on color { ColorAnimation { duration: 80 } }
        }

        MouseArea {
            id: iDrag
            anchors.fill: parent
            function setVal(mx) {
                let pct = Math.max(0, Math.min(1, (mx - 8) / iTrack.width))
                let raw = iSlider.from + pct * (iSlider.to - iSlider.from)
                iSlider.value = parseFloat((Math.round(raw / iSlider.stepSize) * iSlider.stepSize).toFixed(10))
            }
            onPressed:          setVal(mouse.x)
            onPositionChanged:  if (pressed) setVal(mouse.x)
            onReleased:         iSlider.released(iSlider.value)
        }
    }

    component ToggleSwitch: Rectangle {
        id: tSwitch
        property bool checked: false
        signal toggled(bool v)

        implicitWidth: 44; implicitHeight: 24; radius: 12
        color: checked
            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 1.0)
            : Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.5)
        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            y: 4
            x: tSwitch.checked ? parent.width - width - 4 : 4
            width: 16; height: 16; radius: 8
            color: tSwitch.checked
                ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 1.0)
                : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.7)
            Behavior on x     { NumberAnimation { duration: 150; easing.type: Easing.OutQuint } }
            Behavior on color { ColorAnimation  { duration: 150 } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: tSwitch.toggled(!tSwitch.checked)
        }
    }

    // ── Root container ────────────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: root.panelOpacity

        transform: Scale {
            origin.x: root.implicitWidth  / 2
            origin.y: root.implicitHeight / 2
            xScale: root.panelScale
            yScale: root.panelScale
        }

        Rectangle {
            anchors.fill: parent; radius: 16
            color: Qt.rgba(Theme.surface_container_low.r, Theme.surface_container_low.g,
                           Theme.surface_container_low.b, 1.0)
            border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
            border.width: 1
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left nav sidebar ──────────────────────────────────────────────
            Item {
                Layout.preferredWidth: 200
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent; radius: 16
                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                   Theme.surface_container.b, 1.0)
                    Rectangle {
                        anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                        width: 16
                        color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g,
                                       Theme.surface_container.b, 1.0)
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true; Layout.bottomMargin: 10; spacing: 8
                        Text { text: "󰒓"; font.family: "monospace"; font.pixelSize: 18; color: Theme.primary }
                        Text { text: "Settings"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 16; font.bold: true }
                    }

                    Repeater {
                        model: root.categories
                        delegate: Item {
                            id: navItem
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 42
                            property bool isSelected: root.selectedCategory === index

                            Rectangle {
                                anchors.fill: parent; radius: 10
                                color: navItem.isSelected
                                    ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                    : navHov.containsMouse
                                        ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                        : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                                Text {
                                    text: navItem.modelData.icon; font.family: "monospace"; font.pixelSize: 16
                                    color: navItem.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                                Text {
                                    text: navItem.modelData.name
                                    color: navItem.isSelected ? Theme.on_primary_container : Theme.on_surface
                                    font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true
                                    Behavior on color { ColorAnimation { duration: 120 } }
                                }
                            }
                            MouseArea { id: navHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.selectedCategory = navItem.index }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Item {
                        Layout.fillWidth: true; implicitHeight: 36
                        Rectangle {
                            anchors.fill: parent; radius: 10
                            color: closeHov.containsMouse
                                ? Qt.rgba(Theme.error_container.r, Theme.error_container.g, Theme.error_container.b, 0.4)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Text { text: "󰅗"; font.family: "monospace"; font.pixelSize: 14; color: Theme.error }
                            Text { text: "Close"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 13 }
                        }
                        MouseArea { id: closeHov; anchors.fill: parent; hoverEnabled: true; onClicked: root.isOpen = false }
                    }
                }
            }

            // ── Content area ──────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    anchors.leftMargin: 20
                    spacing: 16

                    Text {
                        text: root.categories[root.selectedCategory].name
                        color: Theme.on_surface; font.family: Theme.fontFamily
                        font.pixelSize: 20; font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true; implicitHeight: 1
                        color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.15)
                    }

                    StackLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        currentIndex: root.selectedCategory

                        // ── 0: Appearance ─────────────────────────────────────
                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: appearanceCol.implicitHeight; clip: true
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.primary; opacity: parent.active ? 0.6 : 0.3 }
                            }

                            ColumnLayout {
                                id: appearanceCol
                                width: parent.width - 8
                                spacing: 10

                                // ── Font Style ────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: fontCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: fontCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 12

                                        ColumnLayout {
                                            spacing: 2
                                            Text { text: "Font Style"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }
                                            Text { text: "Interface & Waybar font  ·  Super+Ctrl+F to cycle"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: root.fontOptions
                                                delegate: Rectangle {
                                                    id: fontChip
                                                    required property string modelData
                                                    required property int    index
                                                    property bool isActive: root.currentFontIndex === index
                                                    Layout.fillWidth: true; implicitHeight: 40; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : chipHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: fontChip.modelData
                                                        color: fontChip.isActive ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    MouseArea {
                                                        id: chipHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: {
                                                            root.currentFontIndex = fontChip.index
                                                            Quickshell.execDetached(["bash",
                                                                Quickshell.env("HOME") + "/.local/bin/waybar-font.sh",
                                                                String(fontChip.index)])
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Color Mode ────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: colorCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: colorCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 12

                                        ColumnLayout {
                                            spacing: 2
                                            Text { text: "Color Mode"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }
                                            Text { text: "Regenerates the color palette from your wallpaper"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: [
                                                    { id: "dark",  icon: "󰖔", label: "Dark"  },
                                                    { id: "light", icon: "󰖙", label: "Light" }
                                                ]
                                                delegate: Rectangle {
                                                    id: modeChip
                                                    required property var modelData
                                                    property bool isActive: root.colorMode === modelData.id
                                                    Layout.fillWidth: true; implicitHeight: 40; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : modeHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    RowLayout {
                                                        anchors.centerIn: parent; spacing: 6
                                                        Text { text: modeChip.modelData.icon; font.family: "monospace"; font.pixelSize: 14; color: modeChip.isActive ? Theme.on_primary_container : Theme.on_surface_variant }
                                                        Text { text: modeChip.modelData.label; font.family: Theme.fontFamily; font.pixelSize: 12; color: modeChip.isActive ? Theme.on_primary_container : Theme.on_surface }
                                                    }
                                                    MouseArea {
                                                        id: modeHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: {
                                                            let m = modeChip.modelData.id
                                                            root.colorMode = m
                                                            Quickshell.execDetached(["bash", "-c",
                                                                "echo " + m + " > $HOME/.config/quickshell/settings/color-mode; " +
                                                                "WALL=$(cat $HOME/.cache/qs-dotfiles/current_wallpaper); " +
                                                                "matugen image \"$WALL\" --source-color-index 0 -m " + m + "; " +
                                                                "qs ipc call theme-manager reload; " +
                                                                "pkill -SIGUSR2 waybar"])
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Wallpaper ─────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12; implicitHeight: 60
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 14; spacing: 12
                                        ColumnLayout {
                                            Layout.fillWidth: true; spacing: 2
                                            Text { text: "Wallpaper"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }
                                            Text { text: "Super+Shift+W"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                        }
                                        Rectangle {
                                            implicitWidth: 36; implicitHeight: 36; radius: 8
                                            color: openWallHov.containsMouse
                                                ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                            Behavior on color { ColorAnimation { duration: 120 } }
                                            Text {
                                                anchors.centerIn: parent; text: "󰋩"
                                                font.family: "monospace"; font.pixelSize: 18
                                                color: openWallHov.containsMouse ? Theme.on_primary_container : Theme.on_surface_variant
                                            }
                                            MouseArea {
                                                id: openWallHov; anchors.fill: parent; hoverEnabled: true
                                                onClicked: {
                                                    root.isOpen = false
                                                    Quickshell.execDetached(["bash", "-c", "qs ipc call wallpaper toggle"])
                                                }
                                            }
                                        }
                                    }
                                }

                                Item { implicitHeight: 4 }
                            }
                        }

                        // ── 1: Input ──────────────────────────────────────────
                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: inputCol.implicitHeight; clip: true
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.primary; opacity: parent.active ? 0.6 : 0.3 }
                            }

                            ColumnLayout {
                                id: inputCol; width: parent.width - 8; spacing: 10

                                // ── Mouse card ────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: mouseCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: mouseCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰍽"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Mouse"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Scroll Speed"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: mouseScrollSlider.value.toFixed(2); color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider {
                                                id: mouseScrollSlider
                                                from: 0.1; to: 2.0; stepSize: 0.05
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "mouse", "scroll", v.toFixed(2)])
                                                }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Sensitivity"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: mouseSensSlider.value.toFixed(2); color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider {
                                                id: mouseSensSlider
                                                from: -1.0; to: 1.0; stepSize: 0.05
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "mouse", "sens", v.toFixed(2)])
                                                }
                                            }
                                        }

                                        RowLayout { Layout.fillWidth: true
                                            ColumnLayout { spacing: 1; Layout.fillWidth: true
                                                Text { text: "Acceleration"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13 }
                                                Text { text: root.accelEnabled ? "adaptive" : "flat (off)"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                            }
                                            ToggleSwitch {
                                                checked: root.accelEnabled
                                                onToggled: function(v) {
                                                    root.accelEnabled = v
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "accel", v ? "adaptive" : "flat"])
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Trackpad card ─────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: tpadCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: tpadCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰟸"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Trackpad"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Scroll Factor"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: tpadScrollSlider.value.toFixed(2); color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider {
                                                id: tpadScrollSlider
                                                from: 0.1; to: 2.0; stepSize: 0.05
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "trackpad", "scroll", v.toFixed(2)])
                                                }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Sensitivity"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: tpadSensSlider.value.toFixed(2); color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider {
                                                id: tpadSensSlider
                                                from: -1.0; to: 1.0; stepSize: 0.05
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "trackpad", "sens", v.toFixed(2)])
                                                }
                                            }
                                        }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Natural Scroll"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.naturalScroll
                                                onToggled: function(v) {
                                                    root.naturalScroll = v
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "natural", v ? "true" : "false"])
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Keyboard card ─────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: kbCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: kbCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰌌"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Keyboard"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Numlock on startup"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.numlockDefault
                                                onToggled: function(v) {
                                                    root.numlockDefault = v
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-scroll.sh",
                                                        "numlock", v ? "true" : "false"])
                                                }
                                            }
                                        }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Layout"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            Rectangle {
                                                implicitHeight: 28
                                                implicitWidth: kbLayoutLabel.implicitWidth + 16
                                                radius: 6
                                                color: Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                                Text {
                                                    id: kbLayoutLabel
                                                    anchors.centerIn: parent
                                                    text: root.kbLayout.toUpperCase()
                                                    color: Theme.on_surface
                                                    font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                }
                                            }
                                        }
                                    }
                                }

                                Item { implicitHeight: 4 }
                            }
                        }

                        // ── 2: Audio & Display ────────────────────────────────
                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: audioCol.implicitHeight; clip: true
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.primary; opacity: parent.active ? 0.6 : 0.3 }
                            }
                            ColumnLayout {
                                id: audioCol; width: parent.width - 8; spacing: 10
                                Repeater { model: root.categories[2].sections; delegate: PlaceholderCard { title: modelData } }
                                Item { implicitHeight: 4 }
                            }
                        }

                        // ── 3: System & Apps ──────────────────────────────────
                        ScrollView {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: sysCol.implicitHeight; clip: true
                            ScrollBar.vertical: ScrollBar {
                                policy: ScrollBar.AsNeeded
                                contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.primary; opacity: parent.active ? 0.6 : 0.3 }
                            }
                            ColumnLayout {
                                id: sysCol; width: parent.width - 8; spacing: 10
                                Repeater { model: root.categories[3].sections; delegate: PlaceholderCard { title: modelData } }
                                Item { implicitHeight: 4 }
                            }
                        }
                    }
                }
            }
        }
    }
}
