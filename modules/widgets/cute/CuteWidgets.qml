import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: ScalerService.s(480)
    implicitHeight: ScalerService.s(205)

    property bool readDone: false
    property bool stretchDone: false
    property bool tidyDone: false
    property bool timerRunning: false
    property bool focusFinished: false
    property int remainingSeconds: 25 * 60
    property int waterCount: 3

    function formatTime(totalSeconds) {
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        return (minutes < 10 ? "0" : "") + minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
    }

    function alphaColor(value, alpha) {
        const baseColor = Qt.color(value);
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, baseColor.a * alpha);
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.timerRunning
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds -= 1;
            }
            if (root.remainingSeconds <= 0) {
                root.remainingSeconds = 0;
                root.timerRunning = false;
                root.focusFinished = true;
            }
        }
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: ScalerService.s(Settings.appearance.radius1)
        color: root.alphaColor(theme.primary.background, glassBg.active ? 0.55 : 0.88)
        border.color: Qt.rgba(0.86, 0.91, 1.0, 0.88)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        clip: true

        GlassPanel {
            id: glassBg
            tint: 0.28
            frostAmount: 0.16
            rim: 0.82
        }

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: FloatingCircles {
                anchors.fill: parent
                circleColor: theme.button.text
                circleCount: 3
                animated: false
                minOpacity: 0.012
                maxOpacity: 0.035
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(10)
            spacing: ScalerService.s(8)

            // Daily checklist
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: ScalerService.s(14)
                color: Qt.rgba(1, 1, 1, 0.085)
                border.color: root.alphaColor(theme.button.border, 0.34)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(6)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(4)
                        Text { text: "♡"; color: theme.normal.red; font.pixelSize: ScalerService.s(16) }
                        Text {
                            text: "Daily quest"
                            color: theme.button.text
                            font.pixelSize: ScalerService.s(13)
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(25)
                        RowLayout {
                            anchors.fill: parent
                            spacing: ScalerService.s(6)
                            Rectangle {
                                Layout.preferredWidth: ScalerService.s(15)
                                Layout.preferredHeight: ScalerService.s(15)
                                radius: ScalerService.s(5)
                                color: root.readDone ? theme.normal.green : Qt.rgba(1, 1, 1, 0.04)
                                border.color: root.readDone ? theme.normal.green : root.alphaColor(theme.button.text, 0.45)
                                Text { anchors.centerIn: parent; text: root.readDone ? "✓" : ""; color: "#ffffff"; font.pixelSize: ScalerService.s(11) }
                            }
                            Text { text: "Read 10m"; color: theme.button.text; font.pixelSize: ScalerService.s(11); elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.readDone = !root.readDone }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(25)
                        RowLayout {
                            anchors.fill: parent
                            spacing: ScalerService.s(6)
                            Rectangle {
                                Layout.preferredWidth: ScalerService.s(15)
                                Layout.preferredHeight: ScalerService.s(15)
                                radius: ScalerService.s(5)
                                color: root.stretchDone ? theme.normal.green : Qt.rgba(1, 1, 1, 0.04)
                                border.color: root.stretchDone ? theme.normal.green : root.alphaColor(theme.button.text, 0.45)
                                Text { anchors.centerIn: parent; text: root.stretchDone ? "✓" : ""; color: "#ffffff"; font.pixelSize: ScalerService.s(11) }
                            }
                            Text { text: "Stretch"; color: theme.button.text; font.pixelSize: ScalerService.s(11); elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.stretchDone = !root.stretchDone }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(25)
                        RowLayout {
                            anchors.fill: parent
                            spacing: ScalerService.s(6)
                            Rectangle {
                                Layout.preferredWidth: ScalerService.s(15)
                                Layout.preferredHeight: ScalerService.s(15)
                                radius: ScalerService.s(5)
                                color: root.tidyDone ? theme.normal.green : Qt.rgba(1, 1, 1, 0.04)
                                border.color: root.tidyDone ? theme.normal.green : root.alphaColor(theme.button.text, 0.45)
                                Text { anchors.centerIn: parent; text: root.tidyDone ? "✓" : ""; color: "#ffffff"; font.pixelSize: ScalerService.s(11) }
                            }
                            Text { text: "Tidy desk"; color: theme.button.text; font.pixelSize: ScalerService.s(11); elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.tidyDone = !root.tidyDone }
                    }

                    Item { Layout.fillHeight: true }
                    Text {
                        text: (Number(root.readDone) + Number(root.stretchDone) + Number(root.tidyDone)) + " / 3 done ✨"
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(10)
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Pomodoro focus timer
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: ScalerService.s(14)
                color: Qt.rgba(1, 1, 1, 0.085)
                border.color: root.alphaColor(theme.button.border, 0.34)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(5)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(4)
                        Text { text: "🍅"; font.pixelSize: ScalerService.s(15) }
                        Text { text: "Focus berry"; color: theme.button.text; font.pixelSize: ScalerService.s(13); font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Item { Layout.fillHeight: true }
                    Text {
                        text: root.formatTime(root.remainingSeconds)
                        color: theme.button.text
                        font.family: "Lilex Nerd Font"
                        font.pixelSize: ScalerService.s(24)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.focusFinished ? "Yay! break time ♡" : (root.timerRunning ? "You got this!" : "A little focus time")
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(10)
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(5)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: ScalerService.s(29)
                            radius: ScalerService.s(9)
                            color: root.alphaColor(theme.normal.green, 0.22)
                            border.color: root.alphaColor(theme.normal.green, 0.45)
                            Text { anchors.centerIn: parent; text: root.timerRunning ? "Ⅱ Pause" : "▶ Start"; color: theme.button.text; font.pixelSize: ScalerService.s(10); font.bold: true }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.remainingSeconds <= 0 || root.focusFinished) {
                                        root.remainingSeconds = 25 * 60;
                                        root.focusFinished = false;
                                    }
                                    root.timerRunning = !root.timerRunning;
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: ScalerService.s(30)
                            Layout.preferredHeight: ScalerService.s(29)
                            radius: ScalerService.s(9)
                            color: root.alphaColor(theme.button.text, 0.08)
                            border.color: root.alphaColor(theme.button.border, 0.4)
                            Text { anchors.centerIn: parent; text: "↺"; color: theme.button.text; font.pixelSize: ScalerService.s(17) }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.timerRunning = false;
                                    root.remainingSeconds = 25 * 60;
                                    root.focusFinished = false;
                                }
                            }
                        }
                    }
                }
            }

            // Water tracker
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: ScalerService.s(14)
                color: Qt.rgba(1, 1, 1, 0.085)
                border.color: root.alphaColor(theme.button.border, 0.34)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(6)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: ScalerService.s(4)
                        Text { text: "💧"; font.pixelSize: ScalerService.s(15) }
                        Text { text: "Water pal"; color: theme.button.text; font.pixelSize: ScalerService.s(13); font.bold: true; elide: Text.ElideRight; Layout.fillWidth: true }
                    }

                    Text {
                        text: root.waterCount + " / 8 glasses"
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(11)
                        Layout.alignment: Qt.AlignHCenter
                    }

                    GridLayout {
                        Layout.alignment: Qt.AlignHCenter
                        columns: 4
                        rowSpacing: ScalerService.s(2)
                        columnSpacing: ScalerService.s(3)

                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                property int glassIndex: index
                                Layout.preferredWidth: ScalerService.s(18)
                                Layout.preferredHeight: ScalerService.s(20)
                                radius: ScalerService.s(5)
                                color: index < root.waterCount ? root.alphaColor(theme.normal.blue, 0.72) : Qt.rgba(1, 1, 1, 0.035)
                                border.color: index < root.waterCount ? theme.normal.blue : root.alphaColor(theme.button.text, 0.35)
                                Text {
                                    anchors.centerIn: parent
                                    text: index < root.waterCount ? "♥" : "♡"
                                    color: index < root.waterCount ? "#ffffff" : theme.button.text
                                    font.pixelSize: ScalerService.s(12)
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.waterCount = parent.glassIndex + 1
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(28)
                        radius: ScalerService.s(9)
                        color: root.alphaColor(theme.normal.blue, 0.20)
                        border.color: root.alphaColor(theme.normal.blue, 0.45)
                        Text { anchors.centerIn: parent; text: root.waterCount >= 8 ? "All filled! ✨" : "+ Add a sip"; color: theme.button.text; font.pixelSize: ScalerService.s(10); font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: root.waterCount = root.waterCount >= 8 ? 0 : root.waterCount + 1 }
                    }
                }
            }
        }
    }
}
