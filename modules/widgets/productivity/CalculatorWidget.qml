import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

Item {
    id: root
    implicitWidth: ScalerService.s(300)
    implicitHeight: ScalerService.s(382)

    property string expression: ""
    property string statusText: "Máy tính nhanh · hỗ trợ ngoặc và %"

    function alphaColor(value, alpha) {
        const c = Qt.color(value);
        return Qt.rgba(c.r, c.g, c.b, c.a * alpha);
    }

    function calculate(source) {
        const normalized = String(source || "").replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-").replace(/\s/g, "");
        if (!normalized.length)
            return "0";
        const tokens = normalized.match(/(?:\d+(?:\.\d*)?|\.\d+|[()+\-*/%])/g);
        if (!tokens || tokens.join("") !== normalized)
            throw new Error("Biểu thức không hợp lệ");
        let position = 0;
        function parsePrimary() {
            const token = tokens[position++];
            let value;
            if (token === "+") {
                value = parsePrimary();
            } else if (token === "-") {
                value = -parsePrimary();
            } else if (token === "(") {
                value = parseExpression();
                if (tokens[position++] !== ")") throw new Error("Thiếu dấu )");
            } else {
                value = Number(token);
                if (token === undefined || token === "" || !isFinite(value))
                    throw new Error("Thiếu số");
            }
            // Percent is postfix (25% = 0.25), matching a pocket calculator.
            while (tokens[position] === "%") {
                position++;
                value /= 100;
            }
            return value;
        }
        function parseTerm() {
            let value = parsePrimary();
            while (position < tokens.length && ["*", "/"].indexOf(tokens[position]) >= 0) {
                const operator = tokens[position++];
                const right = parsePrimary();
                if (operator === "/" && right === 0)
                    throw new Error("Không thể chia cho 0");
                if (operator === "*") value *= right;
                else value /= right;
            }
            return value;
        }
        function parseExpression() {
            let value = parseTerm();
            while (position < tokens.length && ["+", "-"].indexOf(tokens[position]) >= 0) {
                const operator = tokens[position++];
                const right = parseTerm();
                value = operator === "+" ? value + right : value - right;
            }
            return value;
        }
        const result = parseExpression();
        if (position !== tokens.length || !isFinite(result))
            throw new Error("Biểu thức không hợp lệ");
        return String(Number(result.toPrecision(12)));
    }

    function pressKey(key) {
        if (key === "C") {
            expression = "";
            statusText = "Đã xóa · sẵn sàng tính toán";
        } else if (key === "⌫") {
            expression = expression.slice(0, -1);
            statusText = "Máy tính nhanh · hỗ trợ ngoặc và %";
        } else if (key === "=") {
            try {
                expression = calculate(expression);
                statusText = "Đã tính xong ♡";
            } catch (error) {
                statusText = error.message || "Biểu thức không hợp lệ";
            }
        } else {
            const mapped = key === "×" ? "*" : key === "÷" ? "/" : key === "−" ? "-" : key;
            expression += mapped;
            statusText = "Máy tính nhanh · hỗ trợ ngoặc và %";
        }
    }

    readonly property var keys: ["C", "⌫", "(", ")", "7", "8", "9", "÷", "4", "5", "6", "×", "1", "2", "3", "−", "0", ".", "%", "+"]

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(18)
        color: root.alphaColor(theme.primary.background, glass.active ? 0.70 : 0.92)
        border.color: Qt.rgba(0.88, 0.92, 1.0, 0.90)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 1
        clip: true
        GlassPanel { id: glass; tint: 0.28; frostAmount: 0.16; rim: 0.82 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(12)
            spacing: ScalerService.s(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(6)
                Text { text: "✧"; color: theme.normal.blue; font.pixelSize: ScalerService.s(22) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: "Calculator"; color: theme.button.text; font.pixelSize: ScalerService.s(16); font.bold: true }
                    Text { text: "tiny math helper"; color: theme.primary.dim_foreground; font.pixelSize: ScalerService.s(10) }
                }
                Text { text: "♡"; color: theme.normal.red; font.pixelSize: ScalerService.s(20) }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(64)
                radius: ScalerService.s(12)
                color: Qt.rgba(1, 1, 1, 0.10)
                border.color: root.alphaColor(theme.button.border, 0.30)
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(8)
                    spacing: ScalerService.s(2)
                    TextField {
                        id: display
                        Layout.fillWidth: true
                        text: root.expression
                        placeholderText: "0"
                        horizontalAlignment: Text.AlignRight
                        color: theme.button.text
                        selectedTextColor: theme.primary.background
                        selectionColor: theme.normal.blue
                        font.pixelSize: ScalerService.s(23)
                        font.family: "Lilex Nerd Font"
                        background: Item {}
                        onTextEdited: root.expression = text
                        onAccepted: root.pressKey("=")
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.statusText
                        color: theme.primary.dim_foreground
                        font.pixelSize: ScalerService.s(9)
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 4
                rowSpacing: ScalerService.s(6)
                columnSpacing: ScalerService.s(6)
                Repeater {
                    model: root.keys
                    delegate: Rectangle {
                        required property int index
                        required property string modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: ScalerService.s(38)
                        radius: ScalerService.s(10)
                        property bool utilityKey: ["C", "⌫", "(", ")"].indexOf(modelData) >= 0
                        property bool operatorKey: ["÷", "×", "−", "+", "%"].indexOf(modelData) >= 0
                        color: utilityKey ? root.alphaColor(theme.normal.magenta, 0.28) : operatorKey ? root.alphaColor(theme.normal.blue, 0.30) : Qt.rgba(1, 1, 1, 0.09)
                        border.color: utilityKey ? root.alphaColor(theme.normal.magenta, 0.38) : root.alphaColor(theme.button.border, 0.28)
                        Text { anchors.centerIn: parent; text: parent.modelData; color: theme.button.text; font.pixelSize: ScalerService.s(16); font.bold: parent.utilityKey || parent.operatorKey }
                        MouseArea { anchors.fill: parent; onClicked: root.pressKey(parent.modelData) }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(36)
                radius: ScalerService.s(11)
                color: root.alphaColor(theme.normal.green, 0.28)
                border.color: root.alphaColor(theme.normal.green, 0.48)
                Text { anchors.centerIn: parent; text: "=   Calculate"; color: theme.button.text; font.pixelSize: ScalerService.s(13); font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: root.pressKey("=") }
            }
        }
    }
}
