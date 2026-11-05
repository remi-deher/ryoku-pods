pragma ComponentBehavior: Bound
import QtQuick
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
    readonly property string variant: service && service.isHeadset ? "max" : service && service.isProSeries ? "pro" : "buds"

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
            color: (root.connected || root.open) ? Theme.accent : Theme.dim
        }

        // Lowest known pod level, shown only when the host gives room for text.
        Text {
            id: batteryText
            anchors.verticalCenter: parent.verticalCenter
            visible: root.density !== "glyph" && root.service !== null && root.lowest >= 0
            text: root.lowest + "%"
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }
    }

    readonly property int lowest: {
        if (!service) return -1;
        var levels = service.isHeadset
            ? [service.headsetBattery.level]
            : [service.leftPod.level, service.rightPod.level];
        var known = levels.filter(function (l) { return l >= 0; });
        return known.length ? Math.min.apply(null, known) : -1;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (!root.pluginApi) return;
            if (mouse.button === Qt.RightButton) {
                if (root.service) root.service.cycleNoiseMode();
            } else if (root.open) {
                root.requestClose();
            } else if (root.pluginApi.togglePanel) {
                root.pluginApi.togglePanel();
            }
        }
    }
}
