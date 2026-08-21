.pragma library

var PRIMARY_UNIT = "contra-keep-on.service"
var LEGACY_UNIT = "overnight-no-sleep.service"
var GLYPH = "󰒳"

function sleepBlockedFromShow(text) {
  var lines = String(text || "").split(/\r?\n/)
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() === "active") return true
  }
  return false
}

function statusCommand() {
  return [
    "systemctl", "--user", "show",
    "-p", "ActiveState", "--value",
    PRIMARY_UNIT, LEGACY_UNIT
  ]
}

function startCommand() {
  return ["bash", "-lc",
    "systemctl --user reset-failed contra-keep-on.service >/dev/null 2>&1 || true; " +
    "if systemctl --user is-active --quiet contra-keep-on.service; then exit 0; fi; " +
    "systemd-run --user --collect --unit=contra-keep-on " +
    "--description='Block sleep from the Keep On applet' " +
    "/usr/bin/systemd-inhibit --what=sleep:handle-lid-switch --who=contra.keep-on " +
    "--why='Keep machine running' --mode=block /usr/bin/sleep infinity"
  ]
}

function stopCommand() {
  return ["systemctl", "--user", "stop", PRIMARY_UNIT, LEGACY_UNIT]
}

function stayAwakeCommand(enable) {
  return ["omarchy", "toggle", "idle", enable ? "stay-awake" : "allow-idle"]
}

function tooltip(sleepBlocked, stayAwake) {
  if (sleepBlocked && stayAwake)
    return "Keep On · sleeping blocked, screen stays on\nRight-click to allow sleep"
  if (sleepBlocked)
    return "Keep On · sleeping blocked\nRight-click to allow sleep"
  if (stayAwake)
    return "Keep On · screen stays on\nRight-click to block sleep"
  return "Keep On · machine can sleep\nRight-click to block sleep"
}

function heroMeta(sleepBlocked, stayAwake) {
  var parts = []
  if (sleepBlocked) parts.push("Don't sleep")
  if (stayAwake) parts.push("Screen on")
  return parts.length ? parts.join(" · ") : "Machine can sleep"
}

function heroDetail(sleepBlocked, stayAwake) {
  return (sleepBlocked || stayAwake) ? "ON" : "OFF"
}

function barActive(sleepBlocked, stayAwake) {
  return !!(sleepBlocked || stayAwake)
}
