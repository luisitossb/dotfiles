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

    property int    currentWaybarFontIndex: 1
    property int    currentQsFontIndex:    1
    property int    currentKittyFontIndex: 0
    property string colorMode:             "dark"
    property int    activeTheme:           0

    readonly property var themes: [
        { name: "Default"   },
        { name: "League"    },
        { name: "Minecraft" }
    ]

    readonly property var fontOptions:      ["Press Start 2P", "Orbitron", "Monocraft", "Audiowide", "Oxanium", "Inter"]
    readonly property var kittyFontOptions: ["JetBrainsMono Nerd Font", "Monocraft"]

    Process {
        id: fontStateProc
        command: ["bash", "-c",
            "cat " + Quickshell.env("HOME") + "/.config/waybar/active-font 2>/dev/null || echo 1"]
        stdout: StdioCollector { onStreamFinished: root.currentWaybarFontIndex = parseInt(this.text.trim()) || 1 }
    }
    Process {
        id: qsFontStateProc
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/settings/active-font"]
        stdout: StdioCollector { onStreamFinished: {
            let name = this.text.trim()
            let idx = root.fontOptions.indexOf(name)
            root.currentQsFontIndex = idx >= 0 ? idx : 1
        }}
    }
    Process {
        id: kittyFontStateProc
        command: ["bash", "-c",
            "grep 'font_family' " + Quickshell.env("HOME") + "/.config/kitty/pixel-font.conf 2>/dev/null | sed 's/font_family //'"]
        stdout: StdioCollector { onStreamFinished: {
            let name = this.text.trim()
            let idx = root.kittyFontOptions.indexOf(name)
            root.currentKittyFontIndex = idx >= 0 ? idx : 0
        }}
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

    // ── System & Apps state ───────────────────────────────────────────────────

    property string sysOs:      ""
    property string sysKernel:  ""
    property string sysDesktop: ""
    property string sysCpu:     ""
    property int    sysCores:   0
    property string sysGpu:     ""
    property string sysRam:     ""
    property string sysUptime:  ""

    // ── Audio & Display state ─────────────────────────────────────────────────

    property bool volMuted:   false
    property bool micMuted:   false
    property bool nightMode:  false
    property int  nightTemp:  4000

    // ── Aesthetics state ──────────────────────────────────────────────────────

    property int  aestheticsGapsIn:   3
    property int  aestheticsGapsOut:  0
    property int  aestheticsBorder:   1
    property int  aestheticsRounding: 10
    property bool aestheticsBlur:     false
    property bool aestheticsShadow:   true
    property bool aestheticsVrr:      false

    // ── Audio devices / monitors / autostart / flatpak ────────────────────────

    property var audioSinks:       []
    property var audioSources:     []
    property var monitors:         []

    Process {
        id: audioDisplayProc
        command: ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/audio-display-state.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                volSlider.value       = d.vol
                micSlider.value       = d.mic
                brightSlider.value    = d.bright
                nightTempSlider.value = d.nightTemp
                root.volMuted         = d.muted
                root.micMuted         = d.micMuted
                root.nightMode        = d.night
                root.nightTemp        = d.nightTemp
            } catch(e) { console.warn("audio-display-state parse error: " + e) }
        }}
    }

    Process {
        id: aestheticsProc
        command: ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/hyprland-aesthetics-state.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                gapsInSlider.value    = d.gaps_in
                gapsOutSlider.value   = d.gaps_out
                borderSlider.value    = d.border
                roundingSlider.value  = d.rounding
                root.aestheticsBlur   = d.blur
                root.aestheticsShadow = d.shadow
                root.aestheticsVrr    = d.vrr
            } catch(e) { console.warn("aesthetics parse error: " + e) }
        }}
    }

    Process {
        id: audioDevicesProc
        command: ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/list-audio-devices.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                root.audioSinks   = d.sinks
                root.audioSources = d.sources
            } catch(e) { console.warn("audio-devices parse error: " + e) }
        }}
    }

    Process {
        id: monitorsProc
        command: ["bash", "-c",
            "hyprctl monitors -j | jq '[.[] | {id,name,res:\"\\(.width)x\\(.height)\",rate:(.refreshRate|floor),scale,x,y}]'"]
        stdout: StdioCollector { onStreamFinished: {
            try { root.monitors = JSON.parse(this.text.trim()) }
            catch(e) { console.warn("monitors parse error: " + e) }
        }}
    }

    Process {
        id: sysInfoProc
        command: ["bash",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/system-info.sh"]
        stdout: StdioCollector { onStreamFinished: {
            try {
                let d = JSON.parse(this.text.trim())
                root.sysOs      = d.os
                root.sysKernel  = d.kernel
                root.sysDesktop = d.desktop
                root.sysCpu     = d.cpu
                root.sysCores   = d.cores
                root.sysGpu     = d.gpu
                root.sysRam     = d.ram
                root.sysUptime  = d.uptime
            } catch(e) { console.warn("system-info parse error: " + e) }
        }}
    }

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
            fontStateProc.running      = false; fontStateProc.running      = true
            qsFontStateProc.running    = false; qsFontStateProc.running    = true
            kittyFontStateProc.running = false; kittyFontStateProc.running = true
            colorModeProc.running    = false; colorModeProc.running    = true
            inputStateProc.running    = false; inputStateProc.running    = true
            audioDisplayProc.running  = false; audioDisplayProc.running  = true
            aestheticsProc.running    = false; aestheticsProc.running    = true
            audioDevicesProc.running  = false; audioDevicesProc.running  = true
            monitorsProc.running      = false; monitorsProc.running      = true
            sysInfoProc.running       = false; sysInfoProc.running       = true
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
        { name: "Audio & Display", icon: "󰕾", sections: [] },
        { name: "System & Apps",   icon: "󰮤", sections: [] }
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
        signal moved(real v)
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
            onPositionChanged:  if (pressed) { setVal(mouse.x); iSlider.moved(iSlider.value) }
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

    component AboutRow: RowLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true; spacing: 0
        Text {
            text: label
            color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 12
            Layout.preferredWidth: 72
        }
        Text {
            text: value
            color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 12
            Layout.fillWidth: true; wrapMode: Text.WordWrap
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

                                // ── Themes ───────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: themesCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: themesCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 12

                                        ColumnLayout { spacing: 2
                                            Text { text: "Themes"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }
                                            Text { text: "Applies font, color mode, and palette"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: root.themes
                                                delegate: Rectangle {
                                                    id: themeChip
                                                    required property var modelData
                                                    required property int index
                                                    property bool isActive: root.activeTheme === index
                                                    Layout.fillWidth: true; implicitHeight: 40; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : themeHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: themeChip.modelData.name
                                                        color: themeChip.isActive ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }

                                                    MouseArea {
                                                        id: themeHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: root.activeTheme = themeChip.index
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

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

                                        Text { text: "Font Style"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14 }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        Text { text: "Waybar"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }

                                        Flow {
                                            id: wbFontFlow
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: root.fontOptions
                                                delegate: Rectangle {
                                                    id: wbFontChip
                                                    required property string modelData
                                                    required property int    index
                                                    property bool isActive: root.currentWaybarFontIndex === index
                                                    width: Math.max(80, wbChipLabel.implicitWidth + 24)
                                                    height: 36; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : wbChipHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        id: wbChipLabel
                                                        anchors.centerIn: parent; text: wbFontChip.modelData
                                                        color: wbFontChip.isActive ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    MouseArea {
                                                        id: wbChipHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: {
                                                            root.currentWaybarFontIndex = wbFontChip.index
                                                            Quickshell.execDetached(["bash",
                                                                Quickshell.env("HOME") + "/.local/bin/waybar-font.sh",
                                                                String(wbFontChip.index)])
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        Text { text: "Quickshell"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }

                                        Flow {
                                            id: qsFontFlow
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: root.fontOptions
                                                delegate: Rectangle {
                                                    id: qsFontChip
                                                    required property string modelData
                                                    required property int    index
                                                    property bool isActive: root.currentQsFontIndex === index
                                                    width: Math.max(80, qsChipLabel.implicitWidth + 24)
                                                    height: 36; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : qsChipHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        id: qsChipLabel
                                                        anchors.centerIn: parent; text: qsFontChip.modelData
                                                        color: qsFontChip.isActive ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    MouseArea {
                                                        id: qsChipHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: {
                                                            root.currentQsFontIndex = qsFontChip.index
                                                            Quickshell.execDetached(["bash", "-c",
                                                                "qs-set-font '" + qsFontChip.modelData + "'"])
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        Text { text: "Kitty"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }

                                        Flow {
                                            id: kittyFontFlow
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: root.kittyFontOptions
                                                delegate: Rectangle {
                                                    id: kittyFontChip
                                                    required property string modelData
                                                    required property int    index
                                                    property bool isActive: root.currentKittyFontIndex === index
                                                    width: Math.max(80, kittyChipLabel.implicitWidth + 24)
                                                    height: 36; radius: 8
                                                    color: isActive
                                                        ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 1.0)
                                                        : kittyChipHov.containsMouse
                                                            ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 1.0)
                                                            : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.5)
                                                    border.color: isActive ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : "transparent"
                                                    border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 120 } }
                                                    Text {
                                                        id: kittyChipLabel
                                                        anchors.centerIn: parent; text: kittyFontChip.modelData
                                                        color: kittyFontChip.isActive ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 11
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    MouseArea {
                                                        id: kittyChipHov; anchors.fill: parent; hoverEnabled: true
                                                        onClicked: {
                                                            root.currentKittyFontIndex = kittyFontChip.index
                                                            Quickshell.execDetached(["bash", "-c",
                                                                "echo 'font_family " + kittyFontChip.modelData + "' > $HOME/.config/kitty/pixel-font.conf; " +
                                                                "kill -SIGUSR1 $(pgrep -x kitty) 2>/dev/null"])
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

                                // ── Aesthetics ────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: aestheticsCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: aestheticsCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󱡓"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Aesthetics"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Gaps (inner)"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: Math.round(gapsInSlider.value) + "px"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider { id: gapsInSlider; from: 0; to: 30; stepSize: 1
                                                onReleased: function(v) { Quickshell.execDetached(["bash", "-c", "hyprctl keyword general:gaps_in " + Math.round(v)]) }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Gaps (outer)"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: Math.round(gapsOutSlider.value) + "px"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider { id: gapsOutSlider; from: 0; to: 30; stepSize: 1
                                                onReleased: function(v) { Quickshell.execDetached(["bash", "-c", "hyprctl keyword general:gaps_out " + Math.round(v)]) }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Border Width"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: Math.round(borderSlider.value) + "px"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider { id: borderSlider; from: 0; to: 8; stepSize: 1
                                                onReleased: function(v) { Quickshell.execDetached(["bash", "-c", "hyprctl keyword general:border_size " + Math.round(v)]) }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Corner Rounding"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text { text: Math.round(roundingSlider.value) + "px"; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true }
                                            }
                                            InputSlider { id: roundingSlider; from: 0; to: 24; stepSize: 1
                                                onReleased: function(v) { Quickshell.execDetached(["bash", "-c", "hyprctl keyword decoration:rounding " + Math.round(v)]) }
                                            }
                                        }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Blur"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.aestheticsBlur
                                                onToggled: function(v) {
                                                    root.aestheticsBlur = v
                                                    Quickshell.execDetached(["bash", "-c", "hyprctl keyword decoration:blur:enabled " + (v ? "true" : "false")])
                                                }
                                            }
                                        }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Shadows"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.aestheticsShadow
                                                onToggled: function(v) {
                                                    root.aestheticsShadow = v
                                                    Quickshell.execDetached(["bash", "-c", "hyprctl keyword decoration:shadow:enabled " + (v ? "true" : "false")])
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

                                // ── Volume card ───────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: volCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: volCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰕾"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Volume"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        // Volume slider row
                                        RowLayout { Layout.fillWidth: true; spacing: 10
                                            Text {
                                                text: root.volMuted ? "󰝟"
                                                    : volSlider.value < 1  ? "󰝟"
                                                    : volSlider.value < 30 ? "󰕿"
                                                    : volSlider.value < 70 ? "󰖀" : "󰕾"
                                                font.family: "monospace"; font.pixelSize: 18
                                                color: root.volMuted ? Theme.on_surface_variant : Theme.primary
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.volMuted = !root.volMuted
                                                        Quickshell.execDetached(["bash", "-c",
                                                            "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"])
                                                    }
                                                }
                                            }
                                            InputSlider {
                                                id: volSlider
                                                from: 0; to: 100; stepSize: 1
                                                onMoved: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(v) + "%"])
                                                }
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(v) + "%"])
                                                }
                                            }
                                            Text {
                                                text: Math.round(volSlider.value) + "%"
                                                color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight
                                            }
                                        }

                                        // Mute toggle row
                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Mute"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.volMuted
                                                onToggled: function(v) {
                                                    root.volMuted = v
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"])
                                                }
                                            }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.08) }

                                        // Mic slider row
                                        RowLayout { Layout.fillWidth: true; spacing: 10
                                            Text {
                                                text: root.micMuted ? "󰍭" : "󰍬"
                                                font.family: "monospace"; font.pixelSize: 18
                                                color: root.micMuted ? Theme.on_surface_variant : Theme.primary
                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        root.micMuted = !root.micMuted
                                                        Quickshell.execDetached(["bash", "-c",
                                                            "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"])
                                                    }
                                                }
                                            }
                                            InputSlider {
                                                id: micSlider
                                                from: 0; to: 150; stepSize: 1
                                                onMoved: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + Math.round(v) + "%"])
                                                }
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ " + Math.round(v) + "%"])
                                                }
                                            }
                                            Text {
                                                text: Math.round(micSlider.value) + "%"
                                                color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight
                                            }
                                        }

                                        // Mic mute toggle row
                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Mic Mute"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.micMuted
                                                onToggled: function(v) {
                                                    root.micMuted = v
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"])
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Brightness card ───────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: brightCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: brightCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰃠"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Brightness"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        RowLayout { Layout.fillWidth: true; spacing: 10
                                            Text {
                                                text: brightSlider.value < 35 ? "󰃞" : brightSlider.value < 70 ? "󰃟" : "󰃠"
                                                font.family: "monospace"; font.pixelSize: 18; color: Theme.primary
                                            }
                                            InputSlider {
                                                id: brightSlider
                                                from: 10; to: 100; stepSize: 1
                                                onMoved: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "brightnessctl set " + Math.round(v) + "%"])
                                                }
                                                onReleased: function(v) {
                                                    Quickshell.execDetached(["bash", "-c",
                                                        "brightnessctl set " + Math.round(v) + "%"])
                                                }
                                            }
                                            Text {
                                                text: Math.round(brightSlider.value) + "%"
                                                color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }

                                // ── Night Mode card ───────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: nightCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: nightCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰖔"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Night Mode"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        RowLayout { Layout.fillWidth: true
                                            Text { text: "Enable"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                            ToggleSwitch {
                                                checked: root.nightMode
                                                onToggled: function(v) {
                                                    root.nightMode = v
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-nightmode.sh",
                                                        v ? "enable" : "disable"])
                                                }
                                            }
                                        }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 6
                                            opacity: root.nightMode ? 1.0 : 0.4
                                            Behavior on opacity { NumberAnimation { duration: 150 } }

                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Color Temperature"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                Text {
                                                    text: Math.round(nightTempSlider.value) + " K"
                                                    color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                }
                                            }
                                            InputSlider {
                                                id: nightTempSlider
                                                from: 2500; to: 6500; stepSize: 100
                                                enabled: root.nightMode
                                                onReleased: function(v) {
                                                    root.nightTemp = Math.round(v)
                                                    Quickshell.execDetached(["bash",
                                                        Quickshell.env("HOME") + "/.local/bin/set-nightmode.sh",
                                                        "temp", String(Math.round(v))])
                                                }
                                            }
                                            RowLayout { Layout.fillWidth: true
                                                Text { text: "Warm"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                                Item { Layout.fillWidth: true }
                                                Text { text: "Cool"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 10 }
                                            }
                                        }
                                    }
                                }

                                // ── Audio Devices card ───────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: devicesCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: devicesCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰓃"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Devices"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        Text { text: "Output"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }

                                        Repeater {
                                            model: root.audioSinks
                                            delegate: Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true; implicitHeight: 36; radius: 8
                                                color: modelData.active
                                                    ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.8)
                                                    : sinkHov.containsMouse
                                                        ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                                        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.4)
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                RowLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                                                    Rectangle {
                                                        implicitWidth: 8; implicitHeight: 8; radius: 4
                                                        color: modelData.active ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    Text {
                                                        text: modelData.desc; Layout.fillWidth: true
                                                        color: modelData.active ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                                MouseArea {
                                                    id: sinkHov; anchors.fill: parent; hoverEnabled: true
                                                    onClicked: {
                                                        Quickshell.execDetached(["bash", "-c",
                                                            "pactl set-default-sink " + modelData.name])
                                                        audioDevicesProc.running = false; audioDevicesProc.running = true
                                                    }
                                                }
                                            }
                                        }

                                        Text { text: "Input"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }

                                        Repeater {
                                            model: root.audioSources
                                            delegate: Rectangle {
                                                required property var modelData
                                                Layout.fillWidth: true; implicitHeight: 36; radius: 8
                                                color: modelData.active
                                                    ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.8)
                                                    : srcHov.containsMouse
                                                        ? Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.8)
                                                        : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.4)
                                                Behavior on color { ColorAnimation { duration: 100 } }

                                                RowLayout { anchors.fill: parent; anchors.margins: 10; spacing: 10
                                                    Rectangle {
                                                        implicitWidth: 8; implicitHeight: 8; radius: 4
                                                        color: modelData.active ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.4)
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                    }
                                                    Text {
                                                        text: modelData.desc; Layout.fillWidth: true
                                                        color: modelData.active ? Theme.on_primary_container : Theme.on_surface
                                                        font.family: Theme.fontFamily; font.pixelSize: 12
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                                MouseArea {
                                                    id: srcHov; anchors.fill: parent; hoverEnabled: true
                                                    onClicked: {
                                                        Quickshell.execDetached(["bash", "-c",
                                                            "pactl set-default-source " + modelData.name])
                                                        audioDevicesProc.running = false; audioDevicesProc.running = true
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── Monitor card ──────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: monitorCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: monitorCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰍹"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Monitor"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        Repeater {
                                            model: root.monitors
                                            delegate: ColumnLayout {
                                                required property var modelData
                                                Layout.fillWidth: true; spacing: 14

                                                // Info row
                                                RowLayout { Layout.fillWidth: true; spacing: 8
                                                    Rectangle {
                                                        implicitHeight: 22; implicitWidth: monNameText.implicitWidth + 12; radius: 6
                                                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                                                        Text { id: monNameText; anchors.centerIn: parent; text: modelData.name; color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 11; font.bold: true }
                                                    }
                                                    Text { text: modelData.res + " @ " + modelData.rate + " Hz"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 12; Layout.fillWidth: true }
                                                }

                                                // Scale slider
                                                ColumnLayout { Layout.fillWidth: true; spacing: 6
                                                    RowLayout { Layout.fillWidth: true
                                                        Text { text: "Scale"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13; Layout.fillWidth: true }
                                                        Text {
                                                            text: monScaleSlider.value.toFixed(2) + "×"
                                                            color: Theme.primary; font.family: Theme.fontFamily; font.pixelSize: 12; font.bold: true
                                                        }
                                                    }
                                                    InputSlider {
                                                        id: monScaleSlider
                                                        from: 0.5; to: 3.0; stepSize: 0.25
                                                        Component.onCompleted: value = modelData.scale
                                                        onReleased: function(v) {
                                                            Quickshell.execDetached(["bash", "-c",
                                                                "hyprctl keyword monitor " + modelData.name + ",preferred,auto," + v.toFixed(2)])
                                                        }
                                                    }
                                                }

                                                // VRR toggle
                                                RowLayout { Layout.fillWidth: true
                                                    ColumnLayout { spacing: 1; Layout.fillWidth: true
                                                        Text { text: "VRR / Adaptive Sync"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 13 }
                                                        Text { text: "Reduces screen tearing"; color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 11 }
                                                    }
                                                    ToggleSwitch {
                                                        checked: root.aestheticsVrr
                                                        onToggled: function(v) {
                                                            root.aestheticsVrr = v
                                                            Quickshell.execDetached(["bash", "-c",
                                                                "hyprctl keyword misc:vrr " + (v ? "1" : "0")])
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Text {
                                            visible: root.monitors.length === 0
                                            text: "No monitors detected"
                                            color: Theme.on_surface_variant; font.family: Theme.fontFamily; font.pixelSize: 12
                                        }
                                    }
                                }

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

                                // ── Power card ────────────────────────────────
                                Rectangle {
                                    id: powerCard
                                    property string pendingAction: ""
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: powerCardCol.implicitHeight + 28

                                    Timer {
                                        id: confirmTimer; interval: 3000
                                        onTriggered: powerCard.pendingAction = ""
                                    }

                                    ColumnLayout {
                                        id: powerCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰐥"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "Power"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        RowLayout {
                                            Layout.fillWidth: true; spacing: 8
                                            Repeater {
                                                model: [
                                                    { icon: "󰌾", label: "Lock",     cmd: "hyprlock",              confirm: false },
                                                    { icon: "󰤄", label: "Suspend",  cmd: "systemctl suspend",     confirm: false },
                                                    { icon: "󰍃", label: "Logout",   cmd: "hyprctl dispatch exit", confirm: true  },
                                                    { icon: "󰜉", label: "Reboot",   cmd: "systemctl reboot",      confirm: true  },
                                                    { icon: "󰚌", label: "Shutdown", cmd: "systemctl poweroff",    confirm: true  }
                                                ]
                                                delegate: Item {
                                                    required property var modelData
                                                    Layout.fillWidth: true; implicitHeight: 64
                                                    property bool isConfirming: powerCard.pendingAction === modelData.label

                                                    Rectangle {
                                                        anchors.fill: parent; radius: 10
                                                        color: isConfirming
                                                            ? Qt.rgba(Theme.error_container.r, Theme.error_container.g, Theme.error_container.b, 0.8)
                                                            : pwrHov.containsMouse
                                                                ? Qt.rgba(Theme.primary_container.r, Theme.primary_container.g, Theme.primary_container.b, 0.8)
                                                                : Qt.rgba(Theme.surface_container_high.r, Theme.surface_container_high.g, Theme.surface_container_high.b, 0.7)
                                                        Behavior on color { ColorAnimation { duration: 120 } }

                                                        ColumnLayout {
                                                            anchors.centerIn: parent; spacing: 4
                                                            Text {
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: modelData.icon; font.family: "monospace"; font.pixelSize: 18
                                                                color: isConfirming ? Theme.error : (pwrHov.containsMouse ? Theme.on_primary_container : Theme.on_surface_variant)
                                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                            }
                                                            Text {
                                                                Layout.alignment: Qt.AlignHCenter
                                                                text: isConfirming ? "Sure?" : modelData.label
                                                                color: isConfirming ? Theme.error : (pwrHov.containsMouse ? Theme.on_primary_container : Theme.on_surface)
                                                                font.family: Theme.fontFamily; font.pixelSize: 11
                                                                Behavior on color { ColorAnimation { duration: 120 } }
                                                            }
                                                        }

                                                        MouseArea {
                                                            id: pwrHov; anchors.fill: parent; hoverEnabled: true
                                                            onClicked: {
                                                                if (!modelData.confirm || isConfirming) {
                                                                    powerCard.pendingAction = ""
                                                                    root.isOpen = false
                                                                    Quickshell.execDetached(["bash", "-c", modelData.cmd])
                                                                } else {
                                                                    powerCard.pendingAction = modelData.label
                                                                    confirmTimer.restart()
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── About card ────────────────────────────────
                                Rectangle {
                                    Layout.fillWidth: true; radius: 12
                                    color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                                    border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.2)
                                    border.width: 1
                                    implicitHeight: aboutCardCol.implicitHeight + 28

                                    ColumnLayout {
                                        id: aboutCardCol
                                        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
                                        spacing: 14

                                        RowLayout { spacing: 8
                                            Text { text: "󰍛"; font.family: "monospace"; font.pixelSize: 16; color: Theme.primary }
                                            Text { text: "About"; color: Theme.on_surface; font.family: Theme.fontFamily; font.pixelSize: 14; font.bold: true }
                                        }

                                        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.12) }

                                        ColumnLayout { Layout.fillWidth: true; spacing: 8
                                            AboutRow { label: "OS";      value: root.sysOs }
                                            AboutRow { label: "Kernel";  value: root.sysKernel }
                                            AboutRow { label: "Desktop"; value: root.sysDesktop }
                                            AboutRow { label: "CPU";     value: root.sysCpu + (root.sysCores > 0 ? "  ·  " + root.sysCores + " threads" : "") }
                                            AboutRow { label: "GPU";     value: root.sysGpu }
                                            AboutRow { label: "RAM";     value: root.sysRam }
                                            AboutRow { label: "Uptime";  value: root.sysUptime }
                                        }
                                    }
                                }

                                Item { implicitHeight: 4 }
                            }
                        }
                    }
                }
            }
        }
    }
}
