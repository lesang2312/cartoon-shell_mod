import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

// Self-contained Caro (Gomoku, 5-in-a-row) mini-game.
// Two local players take turns; first to line up 5 marks (any direction) wins.
// Usage: CaroGame { anchors.fill: parent; onBackRequested: /* switch view back */ }
Item {
    id: game

    signal backRequested

    // ---------- Board definition ----------
    readonly property int cols: 15
    readonly property int rows: 15
    readonly property int winLength: 5

    property var board: []         // mutable 2D array of '', 'X' or 'O' (reset each round)
    property int currentPlayer: 1  // 1 = X, 2 = O
    property int scoreX: 0
    property int scoreO: 0

    property int cursorRow: Math.floor(rows / 2)
    property int cursorCol: Math.floor(cols / 2)

    property bool gameActive: false
    property bool gameOver: false
    property string winner: ""     // "X", "O" or "Draw"
    property var winCells: []      // [{row, col}, ...] winning line, for highlighting

    // ---------- Layout / geometry ----------
    property real cellSize: Math.max(8, Math.floor(Math.min(boardArea.width / cols, boardArea.height / rows)))
    readonly property real boardPixelWidth: cellSize * cols
    readonly property real boardPixelHeight: cellSize * rows
    readonly property real boardOffsetX: (boardArea.width - boardPixelWidth) / 2
    readonly property real boardOffsetY: (boardArea.height - boardPixelHeight) / 2

    function cellValue(row, col) {
        if (row < 0 || row >= rows || col < 0 || col >= cols)
            return '#';
        return board[row][col];
    }

    // IMPORTANT: board is a QML `var` property holding nested JS arrays.
    // Mutating a nested cell in place (board[r][c] = x) does NOT change the
    // property's reference, so QML never fires boardChanged and the bound
    // delegates never re-render. Always go through this helper, which
    // rebuilds the row (and the top-level array) and reassigns `board` so
    // the change is actually observed by bindings.
    function setCell(row, col, value) {
        var newData = board.slice();
        var newRow = newData[row].slice();
        newRow[col] = value;
        newData[row] = newRow;
        board = newData;
    }

    function buildBoard() {
        var data = [];
        for (var r = 0; r < rows; r++) {
            var rowArr = [];
            for (var c = 0; c < cols; c++)
                rowArr.push('');
            data.push(rowArr);
        }
        board = data;
    }

    function isBoardFull() {
        for (var r = 0; r < rows; r++)
            for (var c = 0; c < cols; c++)
                if (board[r][c] === '')
                    return false;
        return true;
    }

    function startGame() {
        buildBoard();
        currentPlayer = 1;
        cursorRow = Math.floor(rows / 2);
        cursorCol = Math.floor(cols / 2);
        winCells = [];
        winner = "";
        gameOver = false;
        gameActive = true;
        game.forceActiveFocus();
    }

    function endGame(result) {
        gameActive = false;
        gameOver = true;
        winner = result;
        if (result === "X")
            scoreX++;
        else if (result === "O")
            scoreO++;
    }

    // Checks the 4 axis directions (horizontal, vertical, 2 diagonals)
    // through (row, col) for `winLength` consecutive matching marks.
    // Records the winning cells (for highlighting) and returns true on a win.
    function checkWinAt(row, col, symbol) {
        var dirs = [[0, 1], [1, 0], [1, 1], [1, -1]];
        for (var d = 0; d < dirs.length; d++) {
            var dr = dirs[d][0];
            var dc = dirs[d][1];
            var cells = [{
                row: row,
                col: col
            }];

            var r = row + dr, c = col + dc;
            while (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] === symbol) {
                cells.push({
                    row: r,
                    col: c
                });
                r += dr;
                c += dc;
            }

            r = row - dr;
            c = col - dc;
            while (r >= 0 && r < rows && c >= 0 && c < cols && board[r][c] === symbol) {
                cells.push({
                    row: r,
                    col: c
                });
                r -= dr;
                c -= dc;
            }

            if (cells.length >= winLength) {
                winCells = cells;
                return true;
            }
        }
        return false;
    }

    function isWinCell(row, col) {
        for (var i = 0; i < winCells.length; i++)
            if (winCells[i].row === row && winCells[i].col === col)
                return true;
        return false;
    }

    function moveCursor(dRow, dCol) {
        cursorRow = Math.max(0, Math.min(rows - 1, cursorRow + dRow));
        cursorCol = Math.max(0, Math.min(cols - 1, cursorCol + dCol));
    }

    function placeMark(row, col) {
        if (!gameActive || gameOver)
            return;
        if (row < 0 || row >= rows || col < 0 || col >= cols)
            return;
        if (board[row][col] !== '')
            return;

        var symbol = currentPlayer === 1 ? 'X' : 'O';
        setCell(row, col, symbol);
        SoundService.playSound("pick");

        if (checkWinAt(row, col, symbol)) {
            endGame(symbol);
            return;
        }
        if (isBoardFull()) {
            endGame("Draw");
            return;
        }
        currentPlayer = currentPlayer === 1 ? 2 : 1;
    }

    Component.onCompleted: startGame()

    // ---------- Input ----------
    focus: true
    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_W:
        case Qt.Key_Up:
            moveCursor(-1, 0);
            event.accepted = true;
            break;
        case Qt.Key_S:
        case Qt.Key_Down:
            moveCursor(1, 0);
            event.accepted = true;
            break;
        case Qt.Key_A:
        case Qt.Key_Left:
            moveCursor(0, -1);
            event.accepted = true;
            break;
        case Qt.Key_D:
        case Qt.Key_Right:
            moveCursor(0, 1);
            event.accepted = true;
            break;
        case Qt.Key_Space:
        case Qt.Key_Return:
        case Qt.Key_Enter:
            placeMark(cursorRow, cursorCol);
            event.accepted = true;
            break;
        }
    }

    // ---------- UI ----------
    ColumnLayout {
        anchors.fill: parent
        spacing: ScalerService.s(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)

            ButtonIconText {
                name: "arrow_back"
                onClicked: game.backRequested()
                textColor: theme.normal.red
            }

            RowLayout {
                spacing: ScalerService.s(6)
                Rectangle {
                    width: ScalerService.s(9)
                    height: width
                    radius: width / 2
                    color: theme.normal.red
                }
                CustomText {
                    name: "" + game.scoreX
                }
                Item {
                    width: ScalerService.s(10)
                }
                Rectangle {
                    width: ScalerService.s(9)
                    height: width
                    radius: width / 2
                    color: theme.normal.cyan
                    border.width: Math.max(1, width * 0.22)
                    border.color: theme.normal.cyan
                }
                CustomText {
                    name: "" + game.scoreO
                }
            }

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                visible: game.gameActive
                spacing: ScalerService.s(6)
                Rectangle {
                    width: ScalerService.s(10)
                    height: width
                    radius: width / 2
                    color: game.currentPlayer === 1 ? theme.normal.red : theme.normal.cyan

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 1
                            to: 0.4
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            from: 0.4
                            to: 1
                            duration: 500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
                CustomText {
                    name: "Turn: " + (game.currentPlayer === 1 ? "X" : "O")
                }
            }
        }

        Item {
            id: boardArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Soft elevated panel behind the grid, instead of a flat void.
            Rectangle {
                x: game.boardOffsetX
                y: game.boardOffsetY
                width: game.boardPixelWidth
                height: game.boardPixelHeight
                radius: ScalerService.s(14)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(theme.button.background.r, theme.button.background.g, theme.button.background.b, 0.55)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(theme.button.background.r, theme.button.background.g, theme.button.background.b, 0.22)
                    }
                }
            }

            Repeater {
                model: game.rows * game.cols
                delegate: Item {
                    id: cellItem
                    property int r: Math.floor(index / game.cols)
                    property int c: index % game.cols
                    // Binding recomputes whenever game.board changes reference (see setCell)
                    property string mark: game.board.length ? game.board[r][c] : ''

                    x: game.boardOffsetX + c * game.cellSize
                    y: game.boardOffsetY + r * game.cellSize
                    width: game.cellSize
                    height: game.cellSize

                    // Cell surface: subtle checkerboard tint, brightens on
                    // hover, glows green when part of the winning line.
                    Rectangle {
                        id: cellBg
                        anchors.fill: parent
                        anchors.margins: Math.max(1, game.cellSize * 0.05)
                        radius: ScalerService.s(4)
                        color: game.isWinCell(r, c) ? Qt.rgba(theme.normal.green.r, theme.normal.green.g, theme.normal.green.b, 0.3) : (cellMouse.containsMouse && cellItem.mark === '' && game.gameActive ? Qt.rgba(theme.normal.yellow.r, theme.normal.yellow.g, theme.normal.yellow.b, 0.14) : ((r + c) % 2 === 0 ? Qt.rgba(1, 1, 1, 0.02) : Qt.rgba(1, 1, 1, 0.045)))

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                    }

                    // Pulsing ring on the keyboard cursor cell.
                    Rectangle {
                        id: cursorRing
                        visible: game.gameActive && r === game.cursorRow && c === game.cursorCol
                        anchors.fill: parent
                        anchors.margins: Math.max(1, game.cellSize * 0.08)
                        radius: ScalerService.s(5)
                        color: "transparent"
                        border.width: Math.max(2, game.cellSize * 0.08)
                        border.color: theme.normal.yellow

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: cursorRing.visible
                            NumberAnimation {
                                from: 1
                                to: 0.35
                                duration: 550
                                easing.type: Easing.InOutQuad
                            }
                            NumberAnimation {
                                from: 0.35
                                to: 1
                                duration: 550
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    // Mark container: pops in with an overshoot when placed.
                    Item {
                        id: markItem
                        anchors.centerIn: parent
                        width: parent.width * 0.56
                        height: parent.height * 0.56
                        scale: cellItem.mark === '' ? 0 : 1

                        Behavior on scale {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.7
                            }
                        }

                        // X: two crossed rounded bars (flat icon, not a glyph).
                        Item {
                            visible: cellItem.mark === 'X'
                            anchors.fill: parent
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: Math.max(2, parent.width * 0.2)
                                radius: height / 2
                                color: theme.normal.red
                                rotation: 45
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: Math.max(2, parent.width * 0.2)
                                radius: height / 2
                                color: theme.normal.red
                                rotation: -45
                            }
                        }

                        // O: a clean ring.
                        Rectangle {
                            visible: cellItem.mark === 'O'
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.width: Math.max(2, parent.width * 0.18)
                            border.color: theme.normal.cyan
                        }
                    }

                    MouseArea {
                        id: cellMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            game.cursorRow = r;
                            game.cursorCol = c;
                            game.placeMark(r, c);
                        }
                    }
                }
            }

            // Glowing strike-through line across the winning 5, instead of
            // just tinting individual cells.
            Rectangle {
                id: winLine
                visible: game.winCells.length >= game.winLength
                property real cx1: game.winCells.length ? game.boardOffsetX + game.winCells[0].col * game.cellSize + game.cellSize / 2 : 0
                property real cy1: game.winCells.length ? game.boardOffsetY + game.winCells[0].row * game.cellSize + game.cellSize / 2 : 0
                property real cx2: game.winCells.length ? game.boardOffsetX + game.winCells[game.winCells.length - 1].col * game.cellSize + game.cellSize / 2 : 0
                property real cy2: game.winCells.length ? game.boardOffsetY + game.winCells[game.winCells.length - 1].row * game.cellSize + game.cellSize / 2 : 0

                width: Math.hypot(cx2 - cx1, cy2 - cy1)
                height: Math.max(4, game.cellSize * 0.14)
                radius: height / 2
                color: theme.normal.green
                opacity: 0.85
                x: cx1
                y: cy1 - height / 2
                transformOrigin: Item.Left
                rotation: Math.atan2(cy2 - cy1, cx2 - cx1) * 180 / Math.PI
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: game.gameOver
        color: Qt.rgba(0, 0, 0, 0.6)

        ColumnLayout {
            anchors.centerIn: parent
            spacing: ScalerService.s(14)

            CustomText {
                Layout.alignment: Qt.AlignHCenter
                name: game.winner === "Draw" ? "Draw!" : game.winner + " wins!"
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                name: "X: " + game.scoreX + "   O: " + game.scoreO
            }
            ButtonText {
                Layout.alignment: Qt.AlignHCenter
                name: "Play Again"
                onClicked: game.startGame()
            }
            ButtonText {
                Layout.alignment: Qt.AlignHCenter
                name: "Back to Menu"
                onClicked: game.backRequested()
            }
        }
    }
}
