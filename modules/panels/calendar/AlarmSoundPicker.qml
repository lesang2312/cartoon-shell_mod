import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.services
import qs.components

// Liệt kê các file âm thanh trong thư mục "sounds" nằm CÙNG chỗ với các file .qml của
// lịch, bằng cách gọi lệnh `ls` (giống cách ReminderService gọi notify-send), thay vì
// dùng Qt.labs.folderlistmodel (không chắc có sẵn trong mọi bản build của quickshell).
// Phát thử âm thanh cũng dùng Process gọi trình phát hệ thống (mpv/ffplay/paplay) thay vì
// QtMultimedia, vì module đó cần cài riêng (qt6-multimedia) và nếu thiếu sẽ làm sập cả
// panel lịch (toàn bộ file .qml không biên dịch được).
// Muốn thêm âm báo mới, chỉ cần copy file .mp3/.wav/.ogg vào thư mục "sounds" rồi bấm
// nút làm mới trong popup này.
Item {
  id: root

  signal soundSelected(string fileUrl, string fileName)
  signal closed

  property string selectedFileUrl: ""
  property string selectedFileName: I18nService.tr("default_sound")

  implicitWidth: ScalerService.s(300)
  implicitHeight: ScalerService.s(380)

  readonly property url soundsDirUrl: Qt.resolvedUrl("./sounds/")
  readonly property string soundsDirPath: soundsDirUrl.toString().replace(/^file:\/\//, "")

  ListModel {
    id: soundModel
  }

  Process {
    id: previewProc
    // Dùng `exec` để trình phát THAY THẾ hẳn tiến trình sh (không phải chạy như con của nó).
    // Nếu chỉ gọi "mpv ... || ffplay ..." thì trình phát là con của sh, và dừng previewProc
    // (running = false) chỉ giết được sh chứ không giết được trình phát -> nhạc vẫn kêu tiếp.
    command: ["sh", "-c", "p=\"$1\"; if command -v mpv >/dev/null 2>&1; then exec mpv --no-video --really-quiet -- \"$p\"; elif command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet -- \"$p\"; else exec paplay -- \"$p\"; fi", "_", ""]
  }

  Process {
    id: listProc
    command: ["sh", "-c", "ls -1 -- '" + root.soundsDirPath.replace(/'/g, "'\\''") + "' 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: root.applyListing(this.text)
    }
  }

  function refresh() {
    listProc.running = true;
  }

  function applyListing(text) {
    soundModel.clear();
    const lines = (text || "").split("\n");
    const exts = ["mp3", "wav", "ogg"];
    for (var i = 0; i < lines.length; i++) {
      var name = lines[i].trim();
      if (name.length === 0)
      continue;
      var dot = name.lastIndexOf(".");
      if (dot < 0)
      continue;
      var ext = name.slice(dot + 1).toLowerCase();
      if (exts.indexOf(ext) === -1)
      continue;
      soundModel.append({
          fileName: name,
          fileUrl: "file://" + root.soundsDirPath + name
      });
    }
  }

  function choose(fileUrl, fileName) {
    root.selectedFileUrl = fileUrl;
    root.selectedFileName = fileName;
    root.soundSelected(fileUrl, fileName);
  }

  function preview(fileUrl) {
    if (previewProc.running)
      previewProc.running = false;
    const localPath = fileUrl.toString().replace(/^file:\/\//, "");
    previewProc.command = ["sh", "-c", "p=\"$1\"; if command -v mpv >/dev/null 2>&1; then exec mpv --no-video --really-quiet -- \"$p\"; elif command -v ffplay >/dev/null 2>&1; then exec ffplay -nodisp -autoexit -loglevel quiet -- \"$p\"; else exec paplay -- \"$p\"; fi", "_", localPath];
    previewProc.running = true;
  }

  // Gọi từ bên ngoài (Popup cha) mỗi khi popup đóng, dù đóng bằng cách nào
  // (bấm ra ngoài, Esc, nút X, hay đã chọn xong 1 âm thanh) — để không bị phát nhạc ngầm mãi.
  function stopPreview() {
    if (previewProc.running)
      previewProc.running = false;
  }

  Component.onCompleted: refresh()

  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(10)

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(6)

      CustomText {
        name: I18nService.tr("alarm_sound_title")
        isBold: true
        size: "normal"
        Layout.fillWidth: true
      }

      ButtonIconText {
        name: "refresh"
        onClicked: root.refresh()
      }
      ButtonIconText {
        name: "close"
        onClicked: root.closed()
      }
    }

    CustomText {
      name: I18nService.tr("alarm_sound_desc")
      size: "small"
      opacity: 0.6
      wrapMode: Text.WordWrap
      Layout.fillWidth: true
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      ListView {
        id: soundList
        anchors.fill: parent
        clip: true
        spacing: ScalerService.s(6)
        model: soundModel

        header: Rectangle {
          width: soundList.width
          height: ScalerService.s(40)
          radius: ScalerService.s(10)
          color: theme.button.background
          opacity: root.selectedFileUrl === "" ? 1 : 0.35
          border.width: root.selectedFileUrl === "" ? ScalerService.s(1) : 0
          border.color: theme.button.text

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(12)
            anchors.rightMargin: ScalerService.s(10)

            ButtonIconText {
              name: "notifications"
            }
            CustomText {
              name: I18nService.tr("default_sound")
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.choose("", I18nService.tr("default_sound"))
          }
        }

        delegate: Rectangle {
          width: soundList.width
          height: ScalerService.s(40)
          radius: ScalerService.s(10)
          color: theme.button.background
          opacity: root.selectedFileUrl === model.fileUrl ? 1 : 0.35
          border.width: root.selectedFileUrl === model.fileUrl ? ScalerService.s(1) : 0
          border.color: theme.button.text

          MouseArea {
            anchors.fill: parent
            onClicked: root.choose(model.fileUrl, model.fileName)
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(12)
            anchors.rightMargin: ScalerService.s(6)

            CustomText {
              name: model.fileName
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            ButtonIconText {
              name: "play_arrow"
              onClicked: root.preview(model.fileUrl)
            }
          }
        }
      }

      // Trạng thái rỗng
      ColumnLayout {
        anchors.centerIn: parent
        visible: soundModel.count === 0
        spacing: ScalerService.s(6)

        ButtonIconText {
          name: "music_off"
          Layout.alignment: Qt.AlignHCenter
          opacity: 0.35
          enabled: false
        }
        CustomText {
          name: I18nService.tr("alarm_sound_empty")
          size: "small"
          textColor: theme.primary.dim_foreground
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
