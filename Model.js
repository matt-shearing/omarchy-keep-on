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
  // One stop per unit: systemctl refuses the whole list if any unit is not loaded.
  return ["bash", "-c",
    "systemctl --user stop " + PRIMARY_UNIT + "; " +
    "systemctl --user stop " + LEGACY_UNIT + " >/dev/null 2>&1 || true"
  ]
}

function tooltip(sleepBlocked) {
  if (sleepBlocked)
    return "Don't sleep · sleeping blocked\nClick to allow sleep"
  return "Don't sleep · machine can sleep\nClick to block sleep"
}
