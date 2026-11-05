# AirPods for Ryoku

Port of [omarchy-pods](https://github.com/thisisgm/omarchy-pods) (MIT, by GM, commit `fff7fec`) to the Ryoku plugin format (`topbarGlyph` + bar panel). Community plugin (`official: false`).

Shows battery per pod and case, listening mode, adaptive noise level, Conversation Awareness, One-Bud ANC and ear detection. Rows are drawn from the capabilities the daemon reports, so each model gets only the controls it has. Left click on the glyph opens the panel; right click cycles the listening mode.

## What runs, reads, writes

- **Reads** `$XDG_STATE_HOME/librepods/status.json` (watched, no polling).
- **Runs** `librepods-ctl <verb>` (argv array, only when you change a setting). Declared in `dependencies.commands`.
- **Writes** nothing itself. No network. One privileged action, only when you run `bin/ryopods-setup` by hand and build packages are missing: `pkexec pacman -S --needed --noconfirm cmake ninja qt6-connectivity qt6-tools qt6-declarative pkgconf libpulse` (polkit prompt).
- `bin/ryopods-setup` and `bin/ryopods-remove` are optional helpers you run by hand. They build/install or remove the daemon in `~/.local` and `~/.config/systemd`-managed user units, and delete `~/.config/AirPodsTrayApp` and `~/.local/state/librepods` on removal (the validator flags these as outside-write warnings; that is intended).

## The daemon is required

The plugin cannot talk to Bluetooth. It needs the patched librepods daemon from omarchy-pods (upstream librepods lacks the status file and the `ca:`/`onebud:`/`adaptive:` verbs). It is not bundled here (GPLv3, C++ source, and a plugin may not download or ship code to run):

```bash
git clone https://github.com/thisisgm/omarchy-pods ~/src/omarchy-pods
~/.local/share/ryoku/plugins/ryoku-pods/bin/ryopods-setup ~/src/omarchy-pods
```

`ryopods-setup` checks the Qt/CMake packages (installs any missing one through `pkexec`), builds, installs to `~/.local`, and enables `librepods.service`.

## Install / remove

```bash
ryoku plugin add . --bar --yes     # from this folder
ryoku plugin remove ryoku-pods
```

## Settings

| key | type | default | description |
| --- | --- | --- | --- |
| hideWhenDisconnected | toggle | true | Hide the glyph when no AirPods are connected |

## Differences from the Omarchy version

- No keyboard navigation (j/k, o/t/n/a) and no IPC target: the Ryoku panel host owns focus and keys.
- No `ctlPath` setting: `librepods-ctl` is resolved on `PATH` (R6).
- Panel is built with `Ryoku.PluginKit` theme tokens instead of Omarchy's `qs.Ui` components; the rotating hero phrases were dropped.
- `service/Model.js` and its test (`deno run --allow-read tests/model.test.js`) are unchanged.

## Status

Validated with `ryoku plugin validate` (0 blocking) and installed. **Not tested against real AirPods** and no `assets/preview-widget.png` yet (capture one on your bar).

## Credits

- Original plugin, panel design, `Model.js` and the patched daemon: **GM** ([thisisgm/omarchy-pods](https://github.com/thisisgm/omarchy-pods), MIT).
- AirPods protocol (AAP over L2CAP, BLE advertisements): **Kavish Devar**, [librepods](https://github.com/kavishdevar/librepods) (GPLv3; the daemon is a modified copy of it).
- Ryoku port: Remi. See `LICENSE`.
