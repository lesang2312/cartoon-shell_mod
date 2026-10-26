import QtQuick
import qs.services

// Một ký tự dot-matrix 5x7 (hoặc ":" rộng 1 cột), vẽ bằng các ô vuông -> không phụ thuộc font
Item {
  id: root

  property string ch: "0"
  property real pixel: ScalerService.s(10)
  property real gap: ScalerService.s(2)
  property color litColor: "#68b6e3"
  property real offOpacity: 0.07

  readonly property var glyphs: ({
      "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
      "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
      "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
      "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
      "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
      "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
      "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
      "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
      "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
      "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
      ":": ["0", "0", "1", "0", "1", "0", "0"]
  })

  readonly property var rows: glyphs[ch] ?? glyphs["0"]
  readonly property int cols: rows[0].length
  readonly property int rowCount: rows.length

  implicitWidth: cols * pixel + (cols - 1) * gap
  implicitHeight: rowCount * pixel + (rowCount - 1) * gap

  Grid {
    columns: root.cols
    spacing: root.gap

    Repeater {
      model: root.cols * root.rowCount
      delegate: Rectangle {
        required property int index
        readonly property bool lit: root.rows[Math.floor(index / root.cols)].charAt(index % root.cols) === "1"
        width: root.pixel
        height: root.pixel
        color: root.litColor
        opacity: lit ? 1.0 : root.offOpacity
      }
    }
  }
}
