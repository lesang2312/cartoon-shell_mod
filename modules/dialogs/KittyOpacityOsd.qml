import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import Quickshell.Io
import qs.components
import qs.services

Scope {
    id: root

    property var theme: ThemeService.theme
    property var lang: LanguageService.translations

    LazyLoader {
        active: KittyOpacityService.popupVisible

        // Cửa sổ phủ toàn màn hình, chỉ để bắt sự kiện "nhấn ra ngoài là tắt"
        PanelWindow {
            id: overlay
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusiveZone: 0
            color: "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: KittyOpacityService.closePopup()
            }

            // ==== NỘI DUNG POPUP (đặt gần góc phải, dưới thanh bar) ====
            Rectangle {
                id: card
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: ScalerService.s(58)
                anchors.rightMargin: ScalerService.s(16)
                implicitWidth: ScalerService.s(320)
                implicitHeight: content.implicitHeight + ScalerService.s(28)
                radius: ScalerService.s(Settings.appearance.radius1)
                color: theme.primary.background
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                border.color: theme.button.border

                // chặn click bên trong card lan ra overlay phía sau
                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ColumnLayout {
                    id: content
                    anchors {
                        fill: parent
                        margins: ScalerService.s(16)
                    }
                    spacing: ScalerService.s(14)

                    // ---- Header ----
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(12)

                        WaterDropGauge {
                            fillValue: KittyOpacityService.displayOpacity
                        }

                        ColumnLayout {
                            spacing: 0
                            CustomText {
                                name: (lang?.kittyOpacity?.title || "Độ trong suốt Kitty")
                                isBold: true
                                size: "small"
                            }
                            CustomText {
                                name: Math.round(KittyOpacityService.displayOpacity) + "%"
                                color: theme.primary.dim_foreground
                                size: "xs"
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // nút đóng, cùng hiệu ứng hover như các nút khác trong shell
                        Rectangle {
                            id: closeBtn
                            Layout.preferredWidth: ScalerService.s(28)
                            Layout.preferredHeight: ScalerService.s(28)
                            radius: width / 2
                            color: closeArea.containsMouse ? theme.normal.red : theme.button.background
                            Behavior on color { ColorAnimation { duration: 250 } }

                            IconText {
                                anchors.centerIn: parent
                                name: "close"
                                size: "xs"
                            }
                            MouseArea {
                                id: closeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SoundService.playSound("pick");
                                    KittyOpacityService.closePopup();
                                }
                            }
                        }
                    }

                    // ---- Slider ----
                    OpacitySlider {
                        Layout.fillWidth: true
                        from: KittyOpacityService.minOpacity * 100
                        to: KittyOpacityService.maxOpacity * 100
                        value: KittyOpacityService.displayOpacity
                        onMoved: KittyOpacityService.setOpacity(value)
                    }

                    // ---- Danh sách phiên kitty ----
                    RowLayout {
                        Layout.fillWidth: true
                        CustomText {
                            name: (lang?.kittyOpacity?.instances || "Phiên kitty")
                            size: "xs"
                            color: theme.primary.dim_foreground
                        }
                        Item { Layout.fillWidth: true }
                        // nút quét lại
                        Rectangle {
                            width: ScalerService.s(22)
                            height: ScalerService.s(22)
                            radius: width / 2
                            color: "transparent"
                            IconText {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: "xs"
                                textColor: theme.button.text
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KittyOpacityService.refreshInstances()
                                onEntered: parent.opacity = 0.7
                                onExited: parent.opacity = 1.0
                            }
                        }
                    }

                    CustomText {
                        visible: !KittyOpacityService.hasInstances
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        size: "xs"
                        color: theme.primary.dim_foreground
                        name: (lang?.kittyOpacity?.empty
                            || "Không tìm thấy phiên kitty nào. Mở kitty với: kitty -o allow_remote_control=yes --listen-on unix:/tmp/kitty_id_$RANDOM")
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(6)
                        visible: KittyOpacityService.hasInstances

                        // chip "Tất cả"
                        CustomRectangle {
                            height: ScalerService.s(26)
                            width: allLabel.implicitWidth + ScalerService.s(18)
                            radius: height / 2
                            color: KittyOpacityService.selectedSockets.length === 0
                                ? theme.button.text
                                : theme.button.background
                            border.width: ScalerService.s(1)
                            border.color: theme.button.border

                            CustomText {
                                id: allLabel
                                anchors.centerIn: parent
                                name: (lang?.kittyOpacity?.all || "Tất cả")
                                size: "xs"
                                textColor: KittyOpacityService.selectedSockets.length === 0
                                    ? theme.primary.background
                                    : theme.primary.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KittyOpacityService.selectAll()
                                onEntered: parent.scale = 1.04
                                onExited: parent.scale = 1.0
                            }
                        }

                        // chip cho từng instance
                        Repeater {
                            model: KittyOpacityService.instances
                            delegate: CustomRectangle {
                                required property var modelData
                                readonly property bool selected: KittyOpacityService.selectedSockets.includes(modelData.socket)

                                height: ScalerService.s(26)
                                width: chipLabel.implicitWidth + ScalerService.s(18)
                                radius: height / 2
                                color: selected ? theme.button.text : theme.button.background
                                border.width: ScalerService.s(1)
                                border.color: theme.button.border

                                CustomText {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    name: modelData.label
                                    size: "xs"
                                    textColor: selected ? theme.primary.background : theme.primary.foreground
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: KittyOpacityService.toggleSelected(modelData.socket)
                                    onEntered: parent.scale = 1.04
                                    onExited: parent.scale = 1.0
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
