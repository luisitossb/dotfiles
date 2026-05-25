import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import qs.CustomTheme

PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "qs-bar"
    exclusionMode: ExclusionMode.Auto

    anchors { left: true; right: true; bottom: true }
    margins { left: 0; right: 0; bottom: 0; top: 0 }

    implicitHeight: 44
    color: "transparent"

    readonly property string home: Quickshell.env("HOME")

    // ── Hyprland data ─────────────────────────────────────────────────────────

    property var clients: []
    property var workspaces: []
    property int activeWorkspaceId: 1
    property string focusedAddress: ""

    function refreshAll() {
        clientsProc.running   = true
        workspacesProc.running = true
        activeWinProc.running  = true
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.clients = JSON.parse(this.text) } catch(e) { root.clients = [] }
            }
        }
    }

    Process {
        id: workspacesProc
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.workspaces = JSON.parse(this.text) } catch(e) { root.workspaces = [] }
            }
        }
    }

    Process {
        id: activeWinProc
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var d = JSON.parse(this.text.trim())
                    root.focusedAddress     = d.address || ""
                    root.activeWorkspaceId  = d.workspace ? d.workspace.id : 1
                } catch(e) {
                    root.focusedAddress = ""
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) { root.refreshAll() }
    }

    Component.onCompleted: root.refreshAll()

    // ── Pill style helper ─────────────────────────────────────────────────────

    readonly property color pillBg: Qt.rgba(23/255, 18/255, 22/255, 0.85)

    component Pill: Rectangle {
        color: root.pillBg
        radius: 14
        implicitHeight: 34
        clip: false
    }

    // ── Hoverable icon button (for cog, sidebar, etc.) ────────────────────────

    component IconBtn: Item {
        id: btn
        property string icon: ""
        property color iconColor: Theme.primary
        property real fontSize: 14
        signal clicked()

        implicitWidth:  btnTxt.implicitWidth + 12
        implicitHeight: parent.height

        Text {
            id: btnTxt
            anchors.centerIn: parent
            text: btn.icon
            font.pixelSize: btn.fontSize
            font.family: "JetBrainsMono Nerd Font"
            color: btn.iconColor
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            visible: btnHov.hovered
        }

        MouseArea {
            anchors.fill: parent
            onClicked: btn.clicked()
            HoverHandler { id: btnHov }
        }
    }

    component LabelBtn: Item {
        id: lbtn
        property string label: ""
        property real fontSize: 12
        signal clicked()

        implicitWidth:  lbtnTxt.implicitWidth + 12
        implicitHeight: parent.height

        Text {
            id: lbtnTxt
            anchors.centerIn: parent
            text: lbtn.label
            font.pixelSize: lbtn.fontSize
            font.family: Theme.fontFamily
            color: Theme.primary
        }

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
            visible: lbtnHov.hovered
        }

        MouseArea {
            anchors.fill: parent
            onClicked: lbtn.clicked()
            HoverHandler { id: lbtnHov }
        }
    }

    // ── Bar layout ────────────────────────────────────────────────────────────

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        // LEFT pill
        Pill {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: leftRow.implicitWidth + 12

            Row {
                id: leftRow
                anchors.centerIn: parent
                spacing: 2
                height: parent.height

                Workspaces {
                    height: parent.height
                    workspaces:        root.workspaces
                    clients:           root.clients
                    activeWorkspaceId: root.activeWorkspaceId
                }

                IconBtn {
                    height: parent.height
                    icon: "󱂬"
                    fontSize: 16
                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "app-launcher", "toggle"])
                }
            }
        }

        // CENTER pill
        Pill {
            id: centerPill
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: Math.max(taskbar.implicitWidth + 12, 80)

            Taskbar {
                id: taskbar
                anchors.centerIn: parent
                height: parent.height
                clients:        root.clients
                focusedAddress: root.focusedAddress
            }
        }

        // RIGHT pill
        Pill {
            id: rightPill
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: rightRow.implicitWidth + 12

            Row {
                id: rightRow
                anchors.centerIn: parent
                spacing: 2
                height: parent.height

                Network     { height: parent.height }
                Bluetooth   { height: parent.height }
                Volume      { height: parent.height }
                Battery     { height: parent.height }
                ModeToggle  { height: parent.height }
                PowerProfile { height: parent.height }

                IconBtn {
                    height: parent.height
                    icon: "󰒓"
                    fontSize: 14
                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "settings-app", "toggle"])
                }

                LabelBtn {
                    height: parent.height
                    label: "LUIS"
                    fontSize: 12
                    onClicked: Quickshell.execDetached(["qs", "ipc", "call", "widget-center", "toggle"])
                }

                Item {
                    height: parent.height
                    implicitWidth: clockTxt.implicitWidth + 16

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        visible: clockHov.hovered
                    }

                    Clock {
                        id: clockTxt
                        anchors.centerIn: parent
                    }

                    HoverHandler { id: clockHov }
                }
            }
        }
    }
}
