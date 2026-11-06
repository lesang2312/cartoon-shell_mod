import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.components

// Khung chung cho một tab cài đặt: tiêu đề + đường kẻ + vùng cuộn. Nội dung con đặt vào trong.
Item {
    id: root

    property var theme: ThemeService.theme
    property string title: ""
    default property alias content: col.data
    property real animationProgress: 0

    NumberAnimation on animationProgress {
        from: 0
        to: 1
        duration: 500
        running: true
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: ScalerService.s(20)
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        Item {
            width: scroll.availableWidth
            implicitHeight: col.implicitHeight + ScalerService.s(36)

            ColumnLayout {
                id: col
                width: parent.width
                spacing: ScalerService.s(16)

                HeaderSettings {
                    name: root.title
                    opacity: root.animationProgress > 0.1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: ScalerService.s(1)
                    color: root.theme.primary.foreground
                    opacity: root.animationProgress > 0.2 ? 0.2 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }
}
