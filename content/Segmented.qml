pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// A row of equal-width options on a hairline frame; the current one gets the thread
// tint and an accent underline. Emits picked(index).
Rectangle {
    id: root

    property var options: []      // array of strings
    property int current: -1
    property real s: 1
    signal picked(int index)

    height: 28 * s
    radius: Theme.radius
    color: "transparent"
    border.width: 1
    border.color: Theme.border

    Row {
        anchors.fill: parent
        anchors.margins: 1

        Repeater {
            model: root.options
            Rectangle {
                id: seg
                required property string modelData
                required property int index
                readonly property bool selected: root.current === index
                width: parent.width / Math.max(1, root.options.length)
                height: parent.height
                color: selected ? Theme.threadBg : (area.containsMouse ? Theme.sheen : "transparent")
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 8 * root.s
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: seg.modelData
                    color: seg.selected ? Theme.bright : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    font.weight: seg.selected ? Font.DemiBold : Font.Normal
                }
                Rectangle {
                    visible: seg.selected
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 2 * root.s
                    color: Theme.accent
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
