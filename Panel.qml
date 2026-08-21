import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Keep On: always-visible bar control for overnight jobs.
//
// First-party StayAwake (in omarchy.indicators) skips lock and screensaver,
// so the panel stays lit. This applet blocks systemd sleep instead, which is
// what actually keeps a copy/compile/agent running. A second toggle still
// reaches the idle service when you do want the screen left on.
Panel {
  id: root

  moduleName: "contra.keep-on"
  ipcTarget: "contra.keep-on"
  manageIpc: false

  property bool sleepBlocked: false
  property bool stayAwakeFile: false
  property bool cursorActive: false
  property int focusIndex: 0

  readonly property color fg: bar ? bar.barForeground : Color.bar.text
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property string home: Quickshell.env("HOME")
  readonly property var idleService: bar && bar.shell ? bar.shell.firstPartyServiceFor("omarchy.idle") : null
  readonly property bool stayAwake: idleService ? idleService.stayAwake : stayAwakeFile
  readonly property bool engaged: Model.barActive(sleepBlocked, stayAwake)

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  function refreshSleep() {
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

  function setStayAwake(on) {
    if (root.idleService) {
      root.idleService.setIdleEnabled(!on)
      return
    }
    runAction(Model.stayAwakeCommand(on))
  }

  function toggleStayAwake() {
    setStayAwake(!root.stayAwake)
  }

  function activateFocused() {
    if (focusIndex === 0) toggleSleepBlocked()
    else toggleStayAwake()
  }

  onOpenedChanged: if (opened) {
    refreshSleep()
    cursorActive = false
    focusIndex = 0
  }

  Component.onCompleted: refreshSleep()

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
    onExited: Qt.callLater(root.refreshSleep)
  }

  FileView {
    id: stayAwakeWatcher
    path: root.home + "/.local/state/omarchy/indicators/stay-awake"
    watchChanges: true
    printErrors: false
    onLoaded: root.stayAwakeFile = true
    onLoadFailed: root.stayAwakeFile = false
    onFileChanged: reload()
  }

  Timer {
    interval: root.opened ? 1500 : 4000
    running: true
    repeat: true
    onTriggered: root.refreshSleep()
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.GLYPH
    active: root.engaged
    dimmed: !root.engaged
    useActiveColor: false
    tooltipText: Model.tooltip(root.sleepBlocked, root.stayAwake)
    onPressed: function(b) {
      if (b === Qt.RightButton) root.toggleSleepBlocked()
      else if (b === Qt.MiddleButton) root.toggleStayAwake()
      else root.toggle()
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        root.cursorActive = true
        var delta = dy !== 0 ? dy : dx
        root.focusIndex = Math.max(0, Math.min(1, root.focusIndex + delta))
      }
      onActivateRequested: if (root.cursorActive) root.activateFocused()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: Style.space(14)

        PanelHero {
          title: "Keep On"
          meta: Model.heroMeta(root.sleepBlocked, root.stayAwake)
          detail: Model.heroDetail(root.sleepBlocked, root.stayAwake)
          foreground: root.fg
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              width: Style.font.display
              height: Style.font.display
              text: Model.GLYPH
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
            }
          }
        }

        PanelSeparator { foreground: root.fg }

        Toggle {
          width: parent.width
          label: "Don't sleep"
          description: "Blocks suspend. Screen can still blank and lock. Clears on reboot."
          checked: root.sleepBlocked
          hasCursor: root.cursorActive && root.focusIndex === 0
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: root.toggleSleepBlocked()
          onHovered: function(isHovered) {
            if (isHovered) {
              root.cursorActive = true
              root.focusIndex = 0
            }
          }
        }

        Toggle {
          width: parent.width
          label: "Keep screen on"
          description: "Skip the screensaver and lock while idle."
          checked: root.stayAwake
          hasCursor: root.cursorActive && root.focusIndex === 1
          foreground: root.fg
          fontFamily: root.fontFamily
          onClicked: root.toggleStayAwake()
          onHovered: function(isHovered) {
            if (isHovered) {
              root.cursorActive = true
              root.focusIndex = 1
            }
          }
        }
      }
    }
  }
}
