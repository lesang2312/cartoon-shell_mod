import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings
import qs.commons
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: ScalerService.s(480)
    implicitHeight: ScalerService.s(360)

    property string noteText: ""
    property var tasks: []
    property bool ready: false

    property Settings store: Settings {
        category: "cartoon_shell_desk_tools"
        property string savedNote: ""
        property string savedTasks: "[]"
    }

    function alphaColor(value, alpha) {
        const base = Qt.color(value);
        return Qt.rgba(base.r, base.g, base.b, base.a * alpha);
    }

    function saveTasks() {
        store.savedTasks = JSON.stringify(root.tasks || []);
    }

    function addTask(value) {
        const label = String(value || "").trim();
        if (!label || root.tasks.length >= 4)
            return false;
        const next = root.tasks.slice();
        next.push({ id: String(Date.now()) + "-" + String(Math.floor(Math.random() * 10000)), text: label, done: false });
        root.tasks = next;
        root.saveTasks();
        return true;
    }

    function toggleTask(taskId, done) {
        root.tasks = root.tasks.map(function (task) {
            return task.id === taskId ? Object.assign({}, task, { done: done }) : task;
        });
        root.saveTasks();
    }

    function removeTask(taskId) {
        root.tasks = root.tasks.filter(function (task) { return task.id !== taskId; });
        root.saveTasks();
    }

    Component.onCompleted: {
        root.noteText = store.savedNote || "";
        try {
            const parsed = JSON.parse(store.savedTasks || "[]");
            root.tasks = Array.isArray(parsed) ? parsed.slice(0, 4) : [];
        } catch (error) {
            root.tasks = [];
        }
        root.ready = true;
    }

    Timer {
        id: noteSaveTimer
        interval: 450
        repeat: false
        onTriggered: store.savedNote = root.noteText
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: ScalerService.s(Settings.appearance.radius1)
        color: glassBg.active ? "transparent" : root.alphaColor(theme.primary.background, 0.62)
        border.color: root.alphaColor(theme.button.border, 0.78)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
        clip: true

        GlassPanel { id: glassBg }

        Loader {
            anchors.fill: parent
            active: true
            sourceComponent: FloatingCircles {
                anchors.fill: parent
                circleColor: theme.button.text
                circleCount: 3
                minOpacity: 0.012
                maxOpacity: 0.035
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(11)
            spacing: ScalerService.s(6)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(6)
                Text {
                    text: "✎"
                    color: theme.normal.blue
                    font.pixelSize: ScalerService.s(20)
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text {
                        text: "Desk tools"
                        color: theme.button.text
                        font.pixelSize: ScalerService.s(16)
                        font.bold: true
                    }
                    Text {
                        text: "Notes & little tasks · auto saved"
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(10)
                    }
                }
                Text {
                    text: "♡"
                    color: theme.normal.red
                    font.pixelSize: ScalerService.s(21)
                }
            }

            // Shortcuts open the shell's existing panels rather than launching arbitrary commands.
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(27)
                spacing: ScalerService.s(5)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.blue, 0.17)
                    border.color: root.alphaColor(theme.normal.blue, 0.36)
                    Text { anchors.centerIn: parent; text: "▦ Calendar"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent; onClicked: VisibleService.togglePanel("calendar") }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.cyan, 0.14)
                    border.color: root.alphaColor(theme.normal.cyan, 0.34)
                    Text { anchors.centerIn: parent; text: "⌁ Wi-Fi"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent; onClicked: VisibleService.togglePanel("wifi") }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.green, 0.14)
                    border.color: root.alphaColor(theme.normal.green, 0.34)
                    Text { anchors.centerIn: parent; text: "▰ Battery"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent; onClicked: VisibleService.togglePanel("battery") }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.red, 0.12)
                    border.color: root.alphaColor(theme.normal.red, 0.30)
                    Text { anchors.centerIn: parent; text: "♫ Music"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent; onClicked: VisibleService.togglePanel("music") }
                }
            }

            Text {
                text: "QUICK NOTE"
                color: theme.primary.dim_foreground
                font.pixelSize: ScalerService.s(9)
                font.bold: true
            }

            TextArea {
                id: noteEditor
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(86)
                text: root.noteText
                placeholderText: "Write a thought, link, or reminder..."
                wrapMode: TextEdit.Wrap
                selectByMouse: true
                color: theme.button.text
                selectedTextColor: theme.primary.background
                selectionColor: theme.normal.blue
                font.pixelSize: ScalerService.s(11)
                background: Rectangle {
                    radius: ScalerService.s(9)
                    color: Qt.rgba(1, 1, 1, 0.045)
                    border.color: root.alphaColor(theme.button.border, 0.32)
                    border.width: 1
                }
                onTextChanged: {
                    if (!root.ready)
                        return;
                    root.noteText = text;
                    noteSaveTimer.restart();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(4)
                Text {
                    text: "TODAY'S TASKS"
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(9)
                    font.bold: true
                    Layout.fillWidth: true
                }
                Text {
                    text: root.tasks.filter(function (task) { return task.done; }).length + " / " + root.tasks.length + " done"
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(9)
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(28)
                spacing: ScalerService.s(5)
                TextField {
                    id: taskInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    placeholderText: root.tasks.length >= 4 ? "Task limit reached" : "Add a small task..."
                    enabled: root.tasks.length < 4
                    color: theme.button.text
                    font.pixelSize: ScalerService.s(11)
                    selectByMouse: true
                    background: Rectangle {
                        radius: ScalerService.s(8)
                        color: Qt.rgba(1, 1, 1, 0.045)
                        border.color: root.alphaColor(theme.button.border, 0.34)
                    }
                    onAccepted: {
                        if (root.addTask(text))
                            text = "";
                    }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(34)
                    Layout.fillHeight: true
                    radius: ScalerService.s(8)
                    color: root.alphaColor(theme.normal.blue, 0.24)
                    border.color: root.alphaColor(theme.normal.blue, 0.5)
                    Text { anchors.centerIn: parent; text: "+"; color: theme.button.text; font.pixelSize: ScalerService.s(18); font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.addTask(taskInput.text))
                                taskInput.text = "";
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(2)

                Repeater {
                    model: root.tasks
                    delegate: Item {
                        id: taskRow
                        property var taskData: modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(22)

                        RowLayout {
                            anchors.fill: parent
                            spacing: ScalerService.s(6)
                            Rectangle {
                                Layout.preferredWidth: ScalerService.s(15)
                                Layout.preferredHeight: ScalerService.s(15)
                                radius: ScalerService.s(5)
                                color: taskRow.taskData.done ? root.alphaColor(theme.normal.green, 0.8) : Qt.rgba(1, 1, 1, 0.035)
                                border.color: taskRow.taskData.done ? theme.normal.green : root.alphaColor(theme.button.text, 0.42)
                                Text { anchors.centerIn: parent; text: taskRow.taskData.done ? "✓" : ""; color: "#ffffff"; font.pixelSize: ScalerService.s(10) }
                                MouseArea { anchors.fill: parent; onClicked: root.toggleTask(taskRow.taskData.id, !taskRow.taskData.done) }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: taskRow.taskData.text
                                color: taskRow.taskData.done ? theme.primary.dim_foreground : theme.button.text
                                font.pixelSize: ScalerService.s(10)
                                font.strikeout: taskRow.taskData.done
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                text: "×"
                                color: theme.primary.dim_foreground
                                font.pixelSize: ScalerService.s(15)
                                MouseArea { anchors.fill: parent; onClicked: root.removeTask(taskRow.taskData.id) }
                            }
                        }
                    }
                }
            }
        }
    }
}
