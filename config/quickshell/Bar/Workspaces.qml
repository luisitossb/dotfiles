import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.CustomTheme

Row {
    id: root
    spacing: 4

    property var workspaces: []
    property var clients: []
    property int activeWorkspaceId: 1

    // Nerd-font icons matching Waybar window-rewrite rules
    function windowIcon(cls) {
        var c = (cls || "").toLowerCase()
        if (c === "kitty")                              return " 󰄛"
        if (c === "discord")                            return " 󰙯"
        if (c === "zen")                                return " 󰈹"
        if (c.indexOf("zed") !== -1)                   return " 󰘐"
        if (c === "spotify")                            return " 󰓇"
        if (c === "steam")                              return " 󰓓"
        if (c === "thunar")                             return " 󰉋"
        if (c === "vlc")                               return " 󰕼"
        if (c === "obsidian")                           return " 󱓧"
        if (c === "telegram" || c.indexOf("tele") !== -1) return " 󰨝"
        if (c.indexOf("code") !== -1 || c.indexOf("vscodium") !== -1) return " 󰨞"
        return " 󰣆"
    }

    property var sortedWorkspaces: {
        var ws = root.workspaces.slice()
        ws.sort(function(a, b) { return a.id - b.id })
        return ws
    }

    Repeater {
        model: root.sortedWorkspaces
        delegate: Item {
            required property var modelData
            required property int index

            readonly property bool isActive: modelData.id === root.activeWorkspaceId
            readonly property var wsClients: root.clients.filter(
                function(c) { return c.workspace && c.workspace.id === modelData.id })

            implicitWidth: wsBg.implicitWidth
            implicitHeight: 34

            Rectangle {
                id: wsBg
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                radius: 6
                color: isActive
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                    : wsHov.hovered
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                        : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                implicitWidth: wsLabel.implicitWidth + 16

                Row {
                    id: wsLabel
                    anchors.centerIn: parent
                    spacing: 0

                    Text {
                        text: modelData.id
                        font.pixelSize: 12
                        font.bold: isActive
                        font.family: "JetBrainsMono Nerd Font"
                        color: isActive ? Theme.primary : Theme.on_surface_variant
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: wsClients
                        delegate: Text {
                            required property var modelData
                            text: root.windowIcon(modelData.class)
                            font.pixelSize: 12
                            font.family: "JetBrainsMono Nerd Font"
                            color: isActive ? Theme.primary : Theme.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    HoverHandler { id: wsHov }
                }
            }
        }
    }

    // New workspace button
    Item {
        implicitWidth: newBg.implicitWidth
        implicitHeight: 34

        Rectangle {
            id: newBg
            anchors.verticalCenter: parent.verticalCenter
            height: 28
            radius: 6
            implicitWidth: newTxt.implicitWidth + 16
            color: newHov.hovered
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)
                : "transparent"

            Text {
                id: newTxt
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 14
                font.bold: true
                color: Theme.on_surface_variant
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("workspace empty")
                HoverHandler { id: newHov }
            }
        }
    }
}
