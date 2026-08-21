# Keep On

![Keep On panel on the Omarchy bar](preview.png)

Stop this machine sleeping while a job runs. The screen can still blank.

Keep On is an [Omarchy](https://omarchy.org) bar applet. **Don't sleep** holds a
user-session inhibit so suspend cannot fire. **Keep screen on** is the first-party
idle override: no screensaver, no lock. The two are independent. Overnight copies
and compiles want the first; a presentation wants both.

Omarchy already ships **Stay Awake** inside `omarchy.indicators`. Hover the center
indicators to see the coffee mark. That control only skips lock and screensaver, so
the panel stays lit. It does not block systemd suspend, and it hides until you
hover. Keep On is the always-visible control for the job that has to finish.

No sudo or pkexec is required. The inhibit is a transient systemd user unit. It
dies on reboot.

## Install

```sh
omarchy plugin add https://github.com/matt-shearing/omarchy-keep-on.git --enable
```

That clones the plugin and can place the widget on the right side of the bar,
next to Power.

## Use

- **Click** the chip — open the panel
- **Right-click** — toggle Don't sleep
- **Middle-click** — toggle Keep screen on

**Don't sleep** blocks suspend and lid-switch sleep. Screensaver, lock, and
display blanking still run on their usual idle timers.

**Keep screen on** calls the same idle service as Stay Awake. The hover coffee
mark lights when this is on.

The chip is bright while either toggle is on, dim when both are off.

## How it works

Don't sleep starts:

```sh
systemd-run --user --collect --unit=contra-keep-on \
  systemd-inhibit --what=sleep:handle-lid-switch --mode=block \
  sleep infinity
```

Turning it off stops `contra-keep-on.service`. An older overnight unit named
`overnight-no-sleep.service` is stopped too, if it is still around.

Keep screen on writes the Stay Awake state file through `omarchy.idle`, or falls
back to `omarchy toggle idle stay-awake` / `allow-idle`.

Nothing in `~/.config` is rewritten except the bar layout entry Omarchy adds when
you enable the plugin.

## Requirements

- Omarchy Quattro with third-party shell plugins
- `systemd --user` and `systemd-inhibit` (already on Omarchy)

## Remove

```sh
omarchy plugin remove contra.keep-on
```

If Don't sleep is still on, stop the unit after removal:

```sh
systemctl --user stop contra-keep-on.service overnight-no-sleep.service
```

## Development

```sh
omarchy plugin validate .
```

Edits under `~/.config/omarchy/plugins/contra.keep-on/` reload in the running
shell. Force a rescan with `omarchy-shell shell rescanPlugins` if a change does
not appear.

## License

MIT. See [LICENSE](LICENSE).
