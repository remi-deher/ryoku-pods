pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Ryoku.PluginKit
import Ryoku.PluginKit.Singletons

// The bar panel: battery per pod and case, listening mode, adaptive level,
// Conversation Awareness, One-Bud ANC and ear detection. Every row is drawn
// from the capability keys the daemon publishes, so a model without a feature
// simply gets no row for it.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 340
    property bool active: false

    readonly property var pods: pluginApi ? pluginApi.mainInstance : null
    readonly property var mdl: pods ? pods.model : null
    readonly property int lowBatteryPercent: pods ? pods.lowBatteryPercent : 20
    readonly property int adaptiveStepPercent: 5
    readonly property int adaptiveSendMs: 150

    readonly property var modes: pods ? pods.availableModes() : []
    readonly property bool adaptiveVisible: pods && pods.hasAirPods && pods.supportsAdaptive && pods.noiseMode === mdl.NOISE_ADAPTIVE
    readonly property string variant: pods ? pods.iconVariant : "buds"
    readonly property string subtitle: !pods ? ""
        : pods.hasAirPods ? root.tr("Connected")
        : pods.schemaUnsupported ? root.tr("Unsupported status schema")
        : pods.daemonReachable ? root.tr("Not connected")
        : root.tr("librepods is not running")

    function tr(s) { return mdl ? mdl.t(s) : s }

    onActiveChanged: if (active && pods) pods.refresh()

    implicitWidth: widthBudget
    implicitHeight: col.implicitHeight + 24 * s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 12 * root.s

        // Header
        Row {
            spacing: 10 * root.s
            AirPodsIcon {
                anchors.verticalCenter: parent.verticalCenter
                iconSize: 30 * root.s
                variant: root.variant
                color: root.pods && root.pods.hasAirPods ? Theme.accent : Theme.dim
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: root.pods && root.pods.modelName !== "" ? root.pods.modelName
                        : root.pods && root.pods.deviceName !== "" ? root.pods.deviceName : "AirPods"
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 16 * root.s
                }
                Text {
                    text: root.subtitle
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
            }
        }

        // Command failure / unreadable status
        Text {
            visible: root.pods && (root.pods.actionStatus !== "" || (root.pods.lastError !== "" && root.pods.daemonReachable))
            width: parent.width
            text: root.pods ? (root.pods.actionStatus !== "" ? root.pods.actionStatus : root.pods.lastError) : ""
            color: Theme.sun
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
        }

        // Battery
        Column {
            visible: root.pods && root.pods.hasBattery
            width: parent.width
            spacing: 6 * root.s

            MicroLabel { s: root.s; label: root.tr("BATTERY") }

            PodRow {
                visible: root.pods && root.pods.isHeadset
                label: root.tr("Headphones")
                pod: root.pods ? ({ level: root.pods.headsetBattery.level, charging: root.pods.headsetBattery.charging, inEar: false }) : null
            }
            PodRow { visible: root.pods && !root.pods.isHeadset; label: root.tr("Left"); pod: root.pods ? root.pods.leftPod : null }
            PodRow { visible: root.pods && !root.pods.isHeadset; label: root.tr("Right"); pod: root.pods ? root.pods.rightPod : null }
            PodRow {
                visible: root.pods && !root.pods.isHeadset
                label: root.tr("Case")
                pod: root.pods ? ({ level: root.pods.caseBattery.level, charging: root.pods.caseBattery.charging, inEar: false }) : null
                meta: !root.pods ? "" : root.pods.caseBattery.level < 0 ? root.tr("Case not heard") : root.mdl.lidText(root.pods.lidState)
            }
        }

        // Listening mode
        Column {
            visible: root.pods && root.pods.hasAirPods && root.modes.length > 0
            width: parent.width
            spacing: 6 * root.s

            MicroLabel { s: root.s; label: root.tr("LISTENING MODE") }

            Repeater {
                model: root.modes
                Rectangle {
                    id: modeRow
                    required property int modelData
                    readonly property bool selected: root.pods.noiseMode === modelData
                    width: parent.width
                    height: 28 * root.s
                    radius: Theme.radius
                    color: modeArea.containsMouse ? Theme.sheen : (modeRow.selected ? Theme.threadBg : "transparent")
                    border.color: modeRow.selected ? Theme.accent : Theme.border
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        x: 10 * root.s
                        text: root.mdl.noiseModeName(modeRow.modelData)
                        color: modeRow.selected ? Theme.bright : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                        font.weight: modeRow.selected ? Font.DemiBold : Font.Normal
                    }
                    MouseArea {
                        id: modeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.pods.setNoiseMode(modeRow.modelData)
                    }
                }
            }

            // Adaptive noise level, only while Adaptive is the active mode
            Column {
                visible: root.adaptiveVisible
                width: parent.width
                spacing: 4 * root.s
                Row {
                    width: parent.width
                    Text {
                        width: parent.width - pct.implicitWidth
                        text: root.tr("Adaptive noise")
                        color: Theme.dim
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                    }
                    Text {
                        id: pct
                        text: root.pods ? root.pods.adaptiveNoiseLevel + "%" : ""
                        color: Theme.bright
                        font.family: Theme.font
                        font.pixelSize: 12 * root.s
                    }
                }
                Item {
                    id: slider
                    width: parent.width
                    height: 16 * root.s
                    property real fraction: dragging ? dragFraction : (root.pods ? root.pods.adaptiveNoiseLevel / 100 : 0)
                    property bool dragging: false
                    property real dragFraction: 0
                    Rectangle {
                        id: thread
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 3 * root.s
                        radius: height / 2
                        color: Theme.threadBg
                        Rectangle {
                            width: parent.width * slider.fraction
                            height: parent.height
                            radius: parent.radius
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.vermDim }
                                GradientStop { position: 1.0; color: Theme.vermLit }
                            }
                        }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width, slider.fraction * parent.width - width / 2))
                        width: 2.5 * root.s
                        height: 11 * root.s
                        color: Theme.bright
                    }
                    property int lastSent: -1
                    function snapped(fraction) {
                        var step = root.adaptiveStepPercent;
                        return Math.round(fraction * 100 / step) * step;
                    }
                    function send(fraction) {
                        var level = snapped(fraction);
                        if (level === lastSent) return;
                        lastSent = level;
                        root.pods.setAdaptiveNoiseLevel(level);
                    }
                    // While dragging, the level is sent at most every adaptiveSendMs, so the
                    // sound follows the thumb without flooding librepods-ctl.
                    Timer {
                        id: dragSend
                        interval: root.adaptiveSendMs
                        repeat: true
                        running: slider.dragging
                        onTriggered: slider.send(slider.dragFraction)
                    }
                    MouseArea {
                        anchors.fill: parent
                        function frac(mx) { return Math.max(0, Math.min(1, mx / width)); }
                        onPressed: function (m) { slider.lastSent = -1; slider.dragging = true; slider.dragFraction = frac(m.x); }
                        onPositionChanged: function (m) { if (slider.dragging) slider.dragFraction = frac(m.x); }
                        onReleased: function (m) {
                            slider.dragging = false;
                            slider.send(frac(m.x));
                        }
                        onCanceled: slider.dragging = false
                    }
                }
            }
        }

        // Toggles
        Column {
            visible: root.pods && root.pods.hasAirPods && (root.pods.supportsConversationalAwareness || root.pods.supportsOneBudANC)
            width: parent.width
            spacing: 6 * root.s
            ToggleRow {
                visible: root.pods && root.pods.supportsConversationalAwareness
                label: root.tr("Conversation Awareness")
                caption: root.tr("Lower the volume when you start talking")
                checked: root.pods ? root.pods.conversationalAwareness : false
                onToggled: root.pods.setConversationalAwareness(!root.pods.conversationalAwareness)
            }
            ToggleRow {
                visible: root.pods && root.pods.supportsOneBudANC
                label: root.tr("One-Bud ANC")
                caption: root.tr("Keep noise cancellation on with one pod in")
                checked: root.pods ? root.pods.oneBudANC : false
                onToggled: root.pods.setOneBudANC(!root.pods.oneBudANC)
            }
        }

        // Ear detection
        Column {
            visible: root.pods && root.pods.hasAirPods
            width: parent.width
            spacing: 6 * root.s

            MicroLabel { s: root.s; label: root.tr("EAR DETECTION") }

            Segmented {
                width: parent.width
                s: root.s
                options: root.mdl ? [root.mdl.earDetectionShort(0), root.mdl.earDetectionShort(1), root.mdl.earDetectionShort(2)] : []
                current: root.pods ? root.pods.earDetectionBehavior : -1
                onPicked: function (i) { root.pods.setEarDetectionBehavior(i) }
            }
            Text {
                width: parent.width
                text: root.pods && root.mdl ? root.mdl.earDetectionName(root.pods.earDetectionBehavior) : ""
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                elide: Text.ElideRight
            }
        }

        // Guidance when nothing is connected
        Text {
            visible: root.pods && !root.pods.hasAirPods && !root.pods.hasBattery && !root.pods.schemaUnsupported
            width: parent.width
            text: root.pods && root.pods.daemonReachable
                ? root.tr("Open the case or connect your AirPods to see battery and listening controls.")
                : root.tr("Start the librepods daemon (systemctl --user start librepods) to see battery and listening controls.")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 13 * root.s
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component PodRow: Item {
        id: podRow
        property string label: ""
        property var pod: null
        property string meta: ""
        readonly property int level: pod ? pod.level : -1
        readonly property bool low: level >= 0 && level <= root.lowBatteryPercent && pod && !pod.charging
        readonly property string metaText: meta !== "" ? meta : (pod ? root.mdl.podMeta(pod) : "")

        width: parent.width
        height: 20 * root.s

        RowLayout {
            anchors.fill: parent
            spacing: 8 * root.s
            Text {
                text: podRow.label
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                Layout.preferredWidth: Math.max(44 * root.s, implicitWidth + 10 * root.s)
            }
            WaveMeter {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                s: root.s
                frac: root.mdl ? root.mdl.levelFraction(podRow.level) : 0
                opacity: podRow.level < 0 ? 0.4 : 1
            }
            Text {
                text: root.mdl ? root.mdl.levelText(podRow.level) : ""
                color: podRow.low ? Theme.sun : Theme.bright
                font.family: Theme.font
                font.pixelSize: 12 * root.s
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 38 * root.s
            }
            Text {
                text: podRow.metaText
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                elide: Text.ElideRight
                Layout.preferredWidth: 56 * root.s
            }
        }
    }

    component ToggleRow: Rectangle {
        id: tr
        property string label: ""
        property string caption: ""
        property bool checked: false
        signal toggled()

        width: parent.width
        height: 40 * root.s
        radius: Theme.radius
        color: trArea.containsMouse ? Theme.sheen : "transparent"
        border.width: 1
        border.color: Theme.border

        Column {
            anchors.verticalCenter: parent.verticalCenter
            x: 10 * root.s
            width: parent.width - 70 * root.s
            Text {
                width: parent.width
                text: tr.label
                color: Theme.bright
                font.family: Theme.font
                font.pixelSize: 13 * root.s
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: tr.caption
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
                elide: Text.ElideRight
            }
        }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 10 * root.s
            width: 30 * root.s
            height: 14 * root.s
            radius: Theme.radius
            color: tr.checked ? Theme.threadBg : "transparent"
            border.width: 1
            border.color: tr.checked ? Theme.accent : Theme.border
            Rectangle {
                y: 2 * root.s
                x: tr.checked ? parent.width - width - 2 * root.s : 2 * root.s
                width: 10 * root.s
                height: parent.height - 4 * root.s
                radius: Theme.radius
                color: tr.checked ? Theme.accent : Theme.dim
                Behavior on x { NumberAnimation { duration: 120 } }
            }
        }
        MouseArea {
            id: trArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tr.toggled()
        }
    }
}
