pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Ryoku.PluginKit.Singletons

// The bar glyph: the AirPods mark matching the connected model, dimmed when
// nothing is connected. Left click opens the panel, right click cycles the
// listening mode (as on the Omarchy original).
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0
    property bool open: false
    property real reveal: 0
    property bool tabActive: false
    signal requestClose()

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool connected: service ? service.hasAirPods : false
    readonly property bool shown: !service || !service.hideWhenDisconnected || service.hasAirPods || service.hasBattery
    readonly property string variant: service ? service.iconVariant : "buds"
    readonly property int lowest: service ? service.displayedLevel : -1
    readonly property bool low: service ? service.displayedLow : false

    visible: shown
    implicitWidth: shown ? Math.ceil(18 * root.s) + (batteryText.visible ? batteryText.implicitWidth + 6 * root.s : 0) : 0
    implicitHeight: Math.max(18 * root.s, 14 * root.s)

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.s

        AirPodsIcon {
            anchors.verticalCenter: parent.verticalCenter
            iconSize: 18 * root.s
            variant: root.variant
            color: root.low ? Theme.sun : (root.connected || root.open) ? Theme.accent : Theme.dim
        }

        // Lowest known pod level, shown only when the host gives room for text.
        Text {
            id: batteryText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.density !== "glyph" && root.service !== null && root.service.showPercentOnGlyph && root.lowest >= 0
            text: root.lowest + "%"
            color: root.low ? Theme.sun : Theme.bright
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (!root.pluginApi) return;
            if (mouse.button === Qt.RightButton) {
                if (root.service && root.service.rightClickAction === "cycle") root.service.cycleNoiseMode();
            } else if (root.open) {
                root.requestClose();
            } else if (root.pluginApi.togglePanel) {
                root.pluginApi.togglePanel();
            }
        }
    }

    // Tooltip: a small PopupWindow under the glyph, shown after a short hover. Only while the
    // panel is closed and there is something to say.
    Timer {
        id: tipDelay
        interval: 450
        onTriggered: root.tipShown = true
    }
    // Closing is debounced so a brief loss of hover (the popup mapping, a pixel of jitter)
    // cannot toggle the tooltip on and off.
    Timer {
        id: tipHide
        interval: 120
        onTriggered: root.tipShown = false
    }
    property bool tipShown: false
    Connections {
        target: area
        function onContainsMouseChanged() {
            if (area.containsMouse) { tipHide.stop(); tipDelay.restart(); }
            else { tipDelay.stop(); tipHide.restart(); }
        }
    }

    Loader {
        active: root.tipShown && !root.open && root.service !== null && root.service.hasBattery
        sourceComponent: PopupWindow {
            visible: true
            color: "transparent"
            // Empty input region: the tooltip never takes the pointer, so it cannot steal
            // the hover from the glyph and make itself close.
            mask: Region { item: null }
            anchor {
                item: root
                edges: Edges.Bottom
                gravity: Edges.Bottom
                rect.width: root.width
                rect.height: root.height + 4 * root.s
            }
            implicitWidth: tipCol.implicitWidth + 20 * root.s
            implicitHeight: tipCol.implicitHeight + 16 * root.s
            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.tileBg
                border.color: Theme.border
                border.width: 1
                Column {
                    id: tipCol
                    x: 10 * root.s
                    y: 8 * root.s
                    spacing: 2 * root.s
                    Repeater {
                        model: root.service ? root.service.tooltipLines : []
                        Text {
                            required property string modelData
                            required property int index
                            text: modelData
                            textFormat: Text.PlainText
                            color: index === 0 ? Theme.bright : Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 12 * root.s
                            font.weight: index === 0 ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
