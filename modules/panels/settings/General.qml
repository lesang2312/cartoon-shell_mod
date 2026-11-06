// components/Settings/GeneralSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import "./general/" as Com
import "./appearance/" as AppCom
import "./" as Bar

Item {
    id: root
    property int currentTab: 0
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    // Timer để reload ngôn ngữ
    property Timer reloadTimer: Timer {
        interval: 30
        repeat: false
        onTriggered: languageLoader.loadLanguage()
    }

    // Chỉ giữ lại giao diện minimal mode
    ColumnLayout {
        anchors.fill: parent
        spacing: ScalerService.s(10)

        // Top Navigation Bar
        Bar.TopNavigationBar {
            animationProgress: root.animationProgress
            indexCategory: 0
            onCurrentTab: function (index) {
                root.currentTab = index;
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            Loader {
                active: root.currentTab === 0
                source: "./general/LanguageRegion.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 0;
                    });
                }
            }

            // Tab 1: Date & Time
            Loader {
                active: root.currentTab === 1
                source: "./general/DateTime.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 1;
                    });
                }
            }

            // Tab 2: Session
            Loader {
                id: tabLoader2
                active: root.currentTab === 2
                source: "./general/Session.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 2;
                    });
                }
                onStatusChanged: if (status === Loader.Error)
                    console.log("[Settings] Không tải được Session.qml")

                // Nếu file lỗi: hiện thông báo thay vì để trống
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: tabLoader2.status === Loader.Error
                    text: "⚠  Không tải được Session.qml\nXem lỗi bằng: qs log | grep -i Session"
                    color: "#ff8a8a"
                    font.pixelSize: ScalerService.s(14)
                }
            }

            // Tab 3: Behavior
            Loader {
                active: root.currentTab === 3
                source: "./general/Behavior.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 3;
                    });
                }
            }

            // Tab 4: Notifications
            Loader {
                id: tabLoader4
                active: root.currentTab === 4
                source: "./general/Notifications.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 4;
                    });
                }
                onStatusChanged: if (status === Loader.Error)
                    console.log("[Settings] Không tải được Notifications.qml")

                // Nếu file lỗi: hiện thông báo thay vì để trống
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: tabLoader4.status === Loader.Error
                    text: "⚠  Không tải được Notifications.qml\nXem lỗi bằng: qs log | grep -i Notifications"
                    color: "#ff8a8a"
                    font.pixelSize: ScalerService.s(14)
                }
            }

            // Tab 5: Privacy
            Loader {
                id: tabLoader5
                active: root.currentTab === 5
                source: "./general/Privacy.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 5;
                    });
                }
                onStatusChanged: if (status === Loader.Error)
                    console.log("[Settings] Không tải được Privacy.qml")

                // Nếu file lỗi: hiện thông báo thay vì để trống
                Text {
                    anchors.centerIn: parent
                    width: parent.width - 40
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    visible: tabLoader5.status === Loader.Error
                    text: "⚠  Không tải được Privacy.qml\nXem lỗi bằng: qs log | grep -i Privacy"
                    color: "#ff8a8a"
                    font.pixelSize: ScalerService.s(14)
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("GeneralSettings loaded");
    }
}
