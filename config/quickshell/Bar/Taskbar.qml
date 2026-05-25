import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.CustomTheme

Item {
    id: root

    readonly property string home: Quickshell.env("HOME")

    property var    clients:        []
    property string focusedAddress: ""
    property var    pinnedApps:     []

    property var  iconCache:    ({})
    property var  iconSeen:     ({})
    property int  iconCacheVer: 0
    property var  iconQueue:    []
    property bool iconBusy:     false

    property int  dragIndex:  -1
    property real dragX:       0.0
    property bool isDragging:  false
    property var  userOrder:   []

    readonly property int itemW:   36
    readonly property int itemSpc:  2
    readonly property int slotW:   38

    function keyFor(item) {
        return item.isPinned ? ("p:" + item.appClass.toLowerCase()) : ("r:" + item.address)
    }

    function syncUserOrder(items) {
        var present = {}
        for (var i = 0; i < items.length; i++) present[keyFor(items[i])] = true
        var kept = []
        for (var j = 0; j < userOrder.length; j++) {
            if (present[userOrder[j]]) kept.push(userOrder[j])
        }
        for (var k = 0; k < items.length; k++) {
            var key = keyFor(items[k])
            if (kept.indexOf(key) < 0) kept.push(key)
        }
        userOrder = kept
    }

    function savePinnedOrder() {
        var byClass = {}
        for (var i = 0; i < pinnedApps.length; i++)
            byClass[pinnedApps[i].class.toLowerCase()] = pinnedApps[i]
        var ordered = []
        for (var j = 0; j < userOrder.length; j++) {
            var k = userOrder[j]
            if (k.indexOf("p:") === 0) {
                var cls = k.substring(2)
                if (byClass[cls]) ordered.push(byClass[cls])
            }
        }
        for (var m = 0; m < pinnedApps.length; m++) {
            var found = false
            for (var n = 0; n < ordered.length; n++) {
                if (ordered[n].class.toLowerCase() === pinnedApps[m].class.toLowerCase()) {
                    found = true; break
                }
            }
            if (!found) ordered.push(pinnedApps[m])
        }
        Quickshell.execDetached([root.home + "/.local/bin/qs-save-pins.sh",
                                 JSON.stringify(ordered)])
    }

    function ensureIcon(cls) {
        if (!cls || iconSeen[cls]) return
        iconSeen[cls] = true
        iconQueue.push(cls)
        if (!iconBusy) drainIcons()
    }

    function drainIcons() {
        if (iconQueue.length === 0) { iconBusy = false; return }
        iconBusy = true
        iconWorker.appClass = iconQueue.shift()
        iconWorker.running  = true
    }

    Process {
        id: iconWorker
        property string appClass: ""
        command: [root.home + "/.local/bin/qs-icon-lookup.py", appClass]
        stdout: StdioCollector {
            onStreamFinished: {
                root.iconCache[iconWorker.appClass] = this.text.trim()
                root.iconCacheVer++
                root.drainIcons()
            }
        }
    }

    property var taskItems: []

    function buildTaskModel() {
        if (root.isDragging) return

        var pinnedClasses = []
        for (var i = 0; i < pinnedApps.length; i++)
            pinnedClasses.push(pinnedApps[i].class.toLowerCase())

        var items = []

        for (var pi = 0; pi < pinnedApps.length; pi++) {
            var p = pinnedApps[pi]
            var cls = p.class.toLowerCase()
            var wins = []
            for (var ci = 0; ci < clients.length; ci++) {
                if (clients[ci].class && clients[ci].class.toLowerCase() === cls)
                    wins.push(clients[ci])
            }
            var isFocused = false
            for (var fi = 0; fi < wins.length; fi++) {
                if (wins[fi].address === focusedAddress) { isFocused = true; break }
            }
            items.push({
                isPinned:  true,
                appClass:  p.class,
                exec:      p.exec || "",
                nerdIcon:  p.icon || "",
                name:      p.name || p.class,
                isRunning: wins.length > 0,
                isFocused: isFocused,
                address:   wins.length > 0 ? wins[0].address : ""
            })
            ensureIcon(p.class)
        }

        for (var wi = 0; wi < clients.length; wi++) {
            var w = clients[wi]
            if (!w.class) continue
            var wCls = w.class.toLowerCase()
            var isPinned = false
            for (var pci = 0; pci < pinnedClasses.length; pci++) {
                if (pinnedClasses[pci] === wCls) { isPinned = true; break }
            }
            if (isPinned) continue
            items.push({
                isPinned:  false,
                appClass:  w.class,
                exec:      "",
                nerdIcon:  "",
                name:      w.title || w.class,
                isRunning: true,
                isFocused: w.address === focusedAddress,
                address:   w.address
            })
            ensureIcon(w.class)
        }

        syncUserOrder(items)
        taskItems = items
    }

    onClientsChanged:        Qt.callLater(buildTaskModel)
    onFocusedAddressChanged: Qt.callLater(buildTaskModel)
    onPinnedAppsChanged:     Qt.callLater(buildTaskModel)

    Process {
        id: pinsProc
        command: ["cat", root.home + "/.config/waybar/pinned-apps.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.pinnedApps = JSON.parse(this.text) }
                catch(e) { root.pinnedApps = [] }
            }
        }
    }

    Component.onCompleted: pinsProc.running = true

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: pinsProc.running = true
    }

    implicitWidth:  taskItems.length > 0 ? taskItems.length * slotW - itemSpc : 0
    implicitHeight: 34

    Item {
        id: taskContainer
        anchors.verticalCenter: parent.verticalCenter
        width:  parent.width
        height: 34

        Repeater {
            model: root.taskItems

            delegate: Item {
                required property var modelData
                required property int index

                width:  root.itemW
                height: 34

                readonly property bool isActive:   modelData.isFocused
                readonly property bool isRunning:  modelData.isRunning
                readonly property bool isPinned:   modelData.isPinned
                readonly property bool amDragging: root.isDragging && root.dragIndex === index

                x: {
                    if (amDragging) return root.dragX
                    var myKey  = root.keyFor(modelData)
                    var mySlot = root.userOrder.indexOf(myKey)
                    return (mySlot >= 0 ? mySlot : index) * root.slotW
                }

                z: amDragging ? 10 : 1

                Behavior on x {
                    enabled: !root.isDragging
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                // Highlight background
                Rectangle {
                    anchors.centerIn: parent
                    width: 32; height: 30
                    radius: 6
                    color: isActive
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                        : itemHov.hovered
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                            : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    // Slightly raise opacity while dragging so item feels "lifted"
                    opacity: amDragging ? 1.0 : 1.0
                }

                // Running indicator dot
                Rectangle {
                    visible: isRunning
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1
                    width: isActive ? 8 : 4
                    height: 2
                    radius: 1
                    color: Theme.primary
                    Behavior on width { NumberAnimation { duration: 120 } }
                }

                // App icon (SVG from theme)
                Image {
                    id: iconImg
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    width: 22; height: 22
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: isPinned && !isRunning ? 0.35 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    source: {
                        var _ = root.iconCacheVer
                        var p = root.iconCache[modelData.appClass]
                        return (p && p.length > 0) ? ("file://" + p) : ""
                    }
                }

                // Nerd font fallback
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: modelData.nerdIcon || ""
                    font.pixelSize: 18
                    font.family: "JetBrainsMono Nerd Font"
                    color: Theme.on_surface
                    opacity: isPinned && !isRunning ? 0.35 : 1.0
                    visible: iconImg.status !== Image.Ready
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                // Hover detection
                HoverHandler { id: itemHov }

                // Click handling — TapHandler dismisses itself if a drag starts
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    gesturePolicy: TapHandler.ReleaseWithinBounds

                    onSingleTapped: function(point, button) {
                        if (root.isDragging) return
                        if (button === Qt.RightButton) {
                            if (modelData.isPinned) {
                                Quickshell.execDetached(["bash",
                                    root.home + "/.local/bin/waybar-unpin.sh",
                                    modelData.appClass])
                            } else {
                                Quickshell.execDetached([root.home + "/.local/bin/waybar-pin.sh"])
                            }
                            return
                        }
                        if (modelData.isRunning && modelData.address) {
                            Hyprland.dispatch("focuswindow address:" + modelData.address)
                        } else if (modelData.exec) {
                            Quickshell.execDetached(modelData.exec.split(" "))
                        }
                    }
                }

                // Drag-to-reorder — DragHandler properly captures and releases the pointer
                // even when the item moves underneath the cursor, so no sticky-drag bugs.
                DragHandler {
                    id: dragHandler
                    target:            null
                    yAxis.enabled:     false
                    dragThreshold:     8

                    property real origX: 0

                    onActiveChanged: {
                        if (active) {
                            // Subtract current translation so origX + translation.x == parent.x (no jump)
                            origX           = parent.x - translation.x
                            root.dragIndex  = index
                            root.isDragging = true
                        } else if (root.dragIndex === index) {
                            // Snap to nearest slot and swap
                            var target = Math.round(root.dragX / root.slotW)
                            target = Math.max(0, Math.min(root.taskItems.length - 1, target))

                            var myKey  = root.keyFor(modelData)
                            var mySlot = root.userOrder.indexOf(myKey)
                            if (mySlot < 0) mySlot = index

                            if (mySlot !== target) {
                                var newOrder = root.userOrder.slice()
                                var tmp = newOrder[target]
                                newOrder[target] = newOrder[mySlot]
                                newOrder[mySlot] = tmp
                                root.userOrder = newOrder
                                root.savePinnedOrder()
                            }

                            root.isDragging = false
                            root.dragIndex  = -1
                        }
                    }

                    onTranslationChanged: {
                        if (active && root.dragIndex === index) {
                            root.dragX = Math.max(0,
                                Math.min((root.taskItems.length - 1) * root.slotW,
                                         origX + translation.x))
                        }
                    }
                }
            }
        }
    }
}
