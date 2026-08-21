# Keep On

![Don't sleep chip on the Omarchy bar](preview.png)

Stop this machine sleeping while a job runs. The screen can still blank.

Keep On is a single [Omarchy](https://omarchy.org) bar chip. Click it to hold a
user-session inhibit so suspend cannot fire. Screensaver, lock, and display
blanking still run on their usual idle timers.

Omarchy already ships **Stay Awake** in the centre indicators (Super+Ctrl+I).
That skips lock and screensaver so the panel stays lit. It does not block
systemd suspend. Use Stay Awake for a presentation; use this for a copy or
compile you want to leave running.

No sudo or pkexec is required. The inhibit is a transient systemd user unit. It
dies on reboot.

## Install

```sh
omarchy plugin add https://github.com/matt-shearing/omarchy-keep-on.git --enable
```

That clones the plugin and can place the chip in the centre of the bar, to the
left of the clock.

## Use

Click the chip to block sleep. Click again to allow it. The mark is bright while
sleep is blocked, dim when the machine can sleep.

## How it works

Turning it on starts:

```sh
systemd-run --user --collect --unit=contra-keep-on \
  systemd-inhibit --what=sleep:handle-lid-switch --mode=block \
  sleep infinity
```

Turning it off stops `contra-keep-on.service`. An older overnight unit named
`overnight-no-sleep.service` is stopped too, if it is still around.

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
