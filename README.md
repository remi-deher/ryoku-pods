# AirPods for Ryoku

Port of [omarchy-pods](https://github.com/thisisgm/omarchy-pods) (MIT, by GM, commit `fff7fec`) to the Ryoku plugin format (`topbarGlyph` + bar panel). Community plugin (`official: false`).

Shows battery per pod and case, listening mode, adaptive noise level, Conversation Awareness, One-Bud ANC and ear detection. Rows are drawn from the capabilities the daemon reports, so each model gets only the controls it has. Left click on the glyph opens the panel; right click cycles the listening mode.

## What runs, reads, writes

- **Reads** `$XDG_STATE_HOME/librepods/status.json` (watched, no polling).
- **Runs** `librepods-ctl <verb>` (argv array, when you change a setting), `bin/ryopods-connect` (the Connection switch: finds the paired Apple device and runs `bluetoothctl connect` or `disconnect`) and `notify-send` (argv array, one desktop notification when a battery gets low, if enabled). Both declared in `dependencies.commands`.
- **Writes** nothing itself. No network. One privileged action, only when you run `bin/ryopods-setup` by hand and build packages are missing: `pkexec pacman -S --needed --noconfirm cmake ninja qt6-connectivity qt6-tools qt6-declarative pkgconf libpulse` (polkit prompt).
- `bin/ryopods-setup` and `bin/ryopods-remove` are optional helpers you run by hand. They build/install or remove the daemon in `~/.local` (build in the cache) and `~/.config/systemd`-managed user units, and delete `~/.config/AirPodsTrayApp` and `~/.local/state/librepods` on removal (the validator flags these as outside-write warnings; that is intended).

## The daemon is required

The plugin cannot talk to Bluetooth. It needs the patched librepods daemon, shipped in `daemon/` (upstream librepods lacks the status file and the `ca:`/`onebud:`/`adaptive:` verbs). It is a modified copy of [librepods](https://github.com/kavishdevar/librepods) by Kavish Devar through GM's fork [omarchy-pods](https://github.com/thisisgm/omarchy-pods), under the **GPLv3** (`daemon/LICENSE`, credits in `daemon/UPSTREAM.md`). It is C++ source that you build yourself, nothing is downloaded or run for you:

```bash
~/.local/share/ryoku/plugins/ryoku-pods/bin/ryopods-setup
```

`ryopods-setup` checks the Qt/CMake packages (installs any missing one through `pkexec`), builds in `~/.cache/ryoku/plugins/ryoku-pods/build`, installs to `~/.local`, keeps the install list in `~/.local/share/librepods/` and enables `librepods.service`. Pass another daemon folder as an argument to build that one instead. `bin/ryopods-remove` undoes it.

## Install / remove

```bash
ryoku plugin add . --bar --yes     # from this folder
ryoku plugin remove ryoku-pods
```

## Settings

| key | type | default | description |
| --- | --- | --- | --- |
| hideWhenDisconnected | toggle | true | Hide the glyph when no AirPods are connected |
| showPercentOnGlyph | toggle | true | Show the percentage next to the glyph (when the bar gives room for text) |
| batteryDisplay | choice | lowest | Which battery the bar shows: lowest pod, left, right or case |
| rightClickAction | choice | cycle | Right click on the glyph: cycle the listening mode, or nothing |
| lowBatteryThreshold | slider | 20 | At or under this level (and not charging) the glyph turns to the warning colour |
| notifyLowBattery | toggle | true | One notification per battery when it gets low; re-armed once it charges or climbs 5 points over the threshold |

Hovering the glyph shows a tooltip with each battery and the listening mode.

## Differences from the Omarchy version

- No keyboard navigation (j/k, o/t/n/a) and no IPC target: the Ryoku panel host owns focus and keys.
- No `ctlPath` setting: `librepods-ctl` is resolved on `PATH` (R6).
- Panel is built with `Ryoku.PluginKit` theme tokens instead of Omarchy's `qs.Ui` components; the rotating hero phrases were dropped.
- `service/Model.js` and its test (`deno run --allow-read tests/model.test.js`) are unchanged.

## Source of truth

This repository is a read-only mirror, rewritten by CI from [remi-deher/linux-plugins](https://github.com/remi-deher/linux-plugins) (`linux/ryoku/ryoku-pods`). Open pull requests and commits there; anything pushed here directly is overwritten on the next sync. Issues can be filed here.

## Status

Validated with `ryoku plugin validate` (0 blocking) and installed. **Not tested against real AirPods** and no `assets/preview-widget.png` yet (capture one on your bar).

## Credits

- Original plugin, panel design, `Model.js` and the daemon fork: **GM** ([thisisgm/omarchy-pods](https://github.com/thisisgm/omarchy-pods), MIT).
- AirPods protocol and the daemon it is built on (`daemon/`): **Kavish Devar** ([kavishdevar/librepods](https://github.com/kavishdevar/librepods), GPLv3). The QR code library in `daemon/thirdparty` is by Project Nayuki (MIT).
- AirPods protocol (AAP over L2CAP, BLE advertisements): **Kavish Devar**, [librepods](https://github.com/kavishdevar/librepods) (GPLv3; the daemon is a modified copy of it).
- Ryoku port: Remi. See `LICENSE`.
