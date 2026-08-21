import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Don't sleep: always-visible centre-bar toggle.
//
// Stay Awake (omarchy.indicators) skips lock and screensaver. This chip
// blocks systemd suspend instead, so a job keeps running while the screen
// may still blank.
BarWidget {
  id: root
  moduleName: "contra.keep-on"

  property bool sleepBlocked: false

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refresh() {
    if (!statusProc.running) statusProc.running = true
  }

  function runAction(command) {
    if (actionProc.running) return
    actionProc.command = command
    actionProc.running = true
  }

  function setSleepBlocked(on) {
    if (on === root.sleepBlocked && !actionProc.running) return
    root.sleepBlocked = on
    runAction(on ? Model.startCommand() : Model.stopCommand())
  }

  function toggleSleepBlocked() {
    setSleepBlocked(!root.sleepBlocked)
  }

  Component.onCompleted: refresh()

  Process {
    id: statusProc
    command: Model.statusCommand()
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.sleepBlocked = Model.sleepBlockedFromShow(text)
    }
  }

  Process {
    id: actionProc
    onExited: Qt.callLater(root.refresh)
  }

  Timer {
    interval: 4000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.GLYPH
    active: root.sleepBlocked
    dimmed: !root.sleepBlocked
    useActiveColor: false
    slotSize: Style.bar.statusSlot
    tooltipText: Model.tooltip(root.sleepBlocked)
    onPressed: root.toggleSleepBlocked()
  }
}
