import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.commons
import qs.components
import qs.services

// Self-contained "Ninja Jump" endless runner mini-game.
// The ninja runs automatically; the player times jumps (and a mid-air
// double jump) to clear shurikens that scroll in from the right.
// Usage: NinjaJumpGame { anchors.fill: parent; onBackRequested: /* switch view back */ }
Item {
    id: game

    signal backRequested

    // ---------- Tunables (derived from play-area size so the feel stays
    // consistent whether this widget is small or large) ----------
    readonly property real groundRatio: 0.74
    readonly property real ninjaSize: Math.max(16, playArea.height * 0.16)
    readonly property real ninjaX: playArea.width * 0.18
    readonly property real gravity: playArea.height * 7.0        // px / s^2
    readonly property real jumpVelocity: -playArea.height * 2.4  // px / s
    readonly property real doubleJumpVelocity: -playArea.height * 2.0
    readonly property real groundY: playArea.height * groundRatio

    // ---------- Simulation state ----------
    property real ninjaY: 0            // 0 = standing on the ground, negative = airborne
    property real ninjaVelocity: 0
    property int jumpsUsed: 0
    property bool landedRecently: false

    property var obstacles: []         // [{x, width, height, passed}, ...]
    property real spawnCountdown: 1.0
    property real obstacleSpeed: 0
    property real spawnInterval: 0
    property int passedCount: 0
    property real groundScroll: 0

    property int score: 0
    property int bestScore: 0
    property bool gameActive: false
    property bool gameOver: false

    // IMPORTANT: obstacles is a QML `var` property holding a JS array.
    // Always reassign it (never mutate an entry in place) so bindings that
    // depend on it - the Repeater delegates - actually re-render.
    function setObstacles(newList) {
        obstacles = newList;
    }

    function reset() {
        ninjaY = 0;
        ninjaVelocity = 0;
        jumpsUsed = 0;
        obstacles = [];
        spawnCountdown = 1.0;
        obstacleSpeed = playArea.width * 0.45;
        spawnInterval = 1.4;
        passedCount = 0;
        groundScroll = 0;
        score = 0;
    }

    function startGame() {
        reset();
        gameOver = false;
        gameActive = true;
        loopTimer.restart();
        game.forceActiveFocus();
    }

    function endGame() {
        gameActive = false;
        gameOver = true;
        loopTimer.stop();
        if (score > bestScore)
            bestScore = score;
    }

    function jump() {
        if (!gameActive)
            return;
        if (jumpsUsed === 0) {
            ninjaVelocity = jumpVelocity;
            jumpsUsed = 1;
        } else if (jumpsUsed === 1) {
            // Mid-air ninja flip: a second, slightly weaker jump.
            ninjaVelocity = doubleJumpVelocity;
            jumpsUsed = 2;
        }
    }

    function spawnObstacle() {
        var h = playArea.height * (0.12 + Math.random() * 0.16);
        var w = playArea.width * (0.05 + Math.random() * 0.03);
        var list = obstacles.slice();
        list.push({
            x: playArea.width + w,
            width: w,
            height: h,
            passed: false
        });
        setObstacles(list);
    }

    function step(dt) {
        if (!gameActive)
            return;

        // --- ninja physics ---
        ninjaVelocity += gravity * dt;
        ninjaY += ninjaVelocity * dt;
        if (ninjaY >= 0) {
            ninjaY = 0;
            ninjaVelocity = 0;
            if (jumpsUsed > 0)
                landedRecently = true;
            jumpsUsed = 0;
        }

        // --- ground scroll (purely visual) ---
        groundScroll += obstacleSpeed * dt;

        // --- obstacles ---
        var list = obstacles.slice();
        var next = [];
        var gained = 0;
        for (var i = 0; i < list.length; i++) {
            var o = list[i];
            o.x -= obstacleSpeed * dt;

            if (!o.passed && o.x + o.width < game.ninjaX) {
                o.passed = true;
                gained += 10;
            }
            // Collision: overlapping in x, and the ninja hasn't jumped
            // above the obstacle's top edge.
            if (o.x < game.ninjaX + game.ninjaSize && o.x + o.width > game.ninjaX && game.ninjaY > -o.height) {
                game.endGame();
                return;
            }
            if (o.x + o.width > -4)
                next.push(o);
        }
        if (gained > 0)
            score += gained;
        setObstacles(next);

        // --- spawning + difficulty ramp ---
        spawnCountdown -= dt;
        if (spawnCountdown <= 0) {
            spawnObstacle();
            spawnInterval = Math.max(0.8, 1.4 - passedCount * 0.02);
            spawnCountdown = spawnInterval * (0.85 + Math.random() * 0.3);
        }
        obstacleSpeed = Math.min(playArea.width * 0.95, playArea.width * 0.45 + score * playArea.width * 0.0006);
        passedCount = Math.floor(score / 10);
    }

    Timer {
        id: loopTimer
        interval: 16
        repeat: true
        running: false
        onTriggered: game.step(interval / 1000)
    }

    // Brief squash pulse right after landing; reset shortly after so the
    // next jump starts from a neutral pose.
    onLandedRecentlyChanged: if (landedRecently)
        landedResetTimer.restart()
    Timer {
        id: landedResetTimer
        interval: 110
        onTriggered: game.landedRecently = false
    }

    Component.onCompleted: startGame()

    // ---------- Input ----------
    focus: true
    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Space:
        case Qt.Key_Up:
        case Qt.Key_W:
            game.jump();
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
            CustomText {
                name: "Score: " + game.score
            }

            Item {
                Layout.fillWidth: true
            }
            CustomText {
                name: "Best: " + game.bestScore
            }
        }

        Item {
            id: playArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            MouseArea {
                anchors.fill: parent
                onClicked: game.jump()
            }

            // Panel behind the track.
            Rectangle {
                anchors.fill: parent
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

            // Ground line.
            Rectangle {
                x: 0
                y: game.groundY
                width: playArea.width
                height: 2
                color: Qt.rgba(1, 1, 1, 0.18)
            }

            // Scrolling dashes on the ground to sell the sense of speed.
            Repeater {
                model: 6
                delegate: Rectangle {
                    required property int index
                    property real spacing: playArea.width / 6
                    width: spacing * 0.4
                    height: 2
                    color: Qt.rgba(1, 1, 1, 0.12)
                    y: game.groundY + 6
                    x: ((spacing * index - game.groundScroll) % (spacing * 6) + spacing * 6) % (spacing * 6)
                }
            }

            // Shurikens.
            Repeater {
                model: game.obstacles
                delegate: Item {
                    required property var modelData
                    x: modelData.x
                    y: game.groundY - modelData.height
                    width: modelData.width
                    height: modelData.height

                    Item {
                        id: spinner
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height)
                        height: width

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 650
                            loops: Animation.Infinite
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: Math.max(2, parent.width * 0.22)
                            radius: height / 2
                            color: theme.primary.dim_foreground
                            rotation: 45
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width
                            height: Math.max(2, parent.width * 0.22)
                            radius: height / 2
                            color: theme.primary.dim_foreground
                            rotation: -45
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.3
                            height: width
                            radius: width / 2
                            color: theme.normal.red
                        }
                    }
                }
            }

            // Ninja.
            Item {
                id: ninjaItem
                width: game.ninjaSize
                height: game.ninjaSize
                x: game.ninjaX
                y: game.groundY - game.ninjaSize + game.ninjaY

                // Item.scale is a single uniform factor, so a real 2-axis
                // squash/stretch needs an explicit Scale transform instead.
                transform: Scale {
                    origin.x: ninjaItem.width / 2
                    origin.y: ninjaItem.height
                    xScale: game.landedRecently ? 1.18 : (game.ninjaVelocity < -40 ? 0.9 : 1.0)
                    yScale: game.landedRecently ? 0.78 : (game.ninjaVelocity < -40 ? 1.18 : 1.0)

                    Behavior on xScale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutQuad
                        }
                    }
                    Behavior on yScale {
                        NumberAnimation {
                            duration: 110
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width * 0.28
                    color: theme.normal.magenta
                }
                // Headband.
                Rectangle {
                    width: parent.width * 1.05
                    height: parent.height * 0.2
                    x: -parent.width * 0.025
                    y: parent.height * 0.28
                    color: theme.normal.red
                }
                // Eye.
                Rectangle {
                    width: Math.max(2, parent.width * 0.14)
                    height: width
                    radius: width / 2
                    color: theme.button.text
                    x: parent.width * 0.6
                    y: parent.height * 0.42
                }
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
                name: "Game Over"
            }
            CustomText {
                Layout.alignment: Qt.AlignHCenter
                name: "Score: " + game.score + "   Best: " + game.bestScore
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
