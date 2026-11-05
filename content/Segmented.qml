pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// A row of equal-width options; the current one is outlined. Emits picked(index).
Rectangle {
    id: root

    property var options: []      // array of strings
    property int current: -1
    property real s: 1
    signal picked(int index)

    height: 28 * s
    radius: Theme.radius
    color: Theme.hair

    Row {
        anchors.fill: parent
        anchors.margins: 2 * root.s
        spacing: 2 * root.s

        Repeater {
            model: root.options
            Rectangle {
                id: seg
                required property string modelData
                required property int index
                readonly property bool selected: root.current === index
                width: (parent.width - (root.options.length - 1) * parent.spacing) / Math.max(1, root.options.length)
                height: parent.height
                radius: Theme.radius
                color: selected ? Theme.threadBg : (area.containsMouse ? Theme.tileBg : "transparent")
                border.color: selected ? Theme.accent : "transparent"
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 8 * root.s
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: seg.modelData
                    color: seg.selected ? Theme.bright : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.picked(seg.index)
                }
            }
        }
    }
}
