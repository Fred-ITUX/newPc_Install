# Fedora KDE changes, scripts outside newPc

What each file in this folder changes compared with its original. Written 2026-11-14.
Full test results: `Nextcloud/MIGRATION_FEDORA_KDE.md`, section "Scripts outside newPc".

To see the exact lines: `diff <original> <file in this folder>` for the full copies.
The `_fed` files hold whole functions; compare each with the function of the same name in the original.

## Function-only files (temporary, for review; nothing sources them)

### `bash_common_fed.sh` → `bash/bash_common.sh`
| Function | Change |
|---|---|
| `get_osname` | Drops the "(… Edition)" part of Fedora's OS name → `fedora_45` |
| `sysInfoCache` | Writes every value shell-quoted (`printf %q`). Fixes the status-bar scripts, which fail on Fedora with a syntax error |

### `bash_functions_fed.sh` → `bash/bash_functions.sh`
| Function | Change |
|---|---|
| `sysUPD` | apt → dnf. 3 steps (upgrade, flatpak, cleanup) instead of 5. A quiet step is still reported if it also shows an error |
| `systemInfo` | Package count from `rpm`; theme, icons, font and Plasma version read from KDE's config |
| `BKP_home` | Backs up `.config` and KWallet; folders that don't exist are skipped. GNOME extensions dropped |
| `extract` | `.rar` goes through `unrar` (Fedora's `7z` cannot open RAR) |
| `latexSET` | Konsole instead of GNOME Terminal |

### `startup_common_fed.sh` → `Startup_Routine/startup_common.sh`
| Function | Change |
|---|---|
| `firewalldStatusCheck` | **Replaces `ufwStatusCheck`.** Checks firewalld is running in zone `block` with nothing open. Heals a stopped firewall or a wrong default zone; reports open services / ports without removing them |
| `launcher_firewalldStatusCheck` | Replaces `launcher_ufwStatusCheck` |
| `SESSION_editing` | Konsole instead of GNOME Terminal |

When moving `firewalldStatusCheck` in: rename the launcher in the `unFuncs` list of `startup_routine.sh` too.

## Full copies

| File | Original | Change |
|---|---|---|
| `enable_sudo_whitelist.sh` | `sudoer/` | `UPDATE` rules: 3 dnf commands. `FIREWALL` rules: 7 firewalld commands + start firewalld. `SMART` unchanged |
| `log_cleaner.py` | `Startup_Routine/` | Removes dnf 5 noise (progress lines, repo refresh, table header, "replacing" lines). apt patterns removed. "0 errors occurred" no longer counts as a problem |
| `night_light.sh` | `Shortcuts/` | New `nightLightSet`: writes KDE Night Light settings to `kwinrc` and asks KWin to reload. Replaces the 5 `gsettings` calls |
| `gpu_watchdog.sh` | `Hardware_Info/` | Fan folder found by the name `amdgpu` instead of the fixed `card1` path |
| `extract.sh` | `Nemo_scripts/` | `.rar` goes through `unrar`, with a pulsing progress bar |
| `git_manager.sh` | `Github/` | `editingUT` no longer copies the GNOME window-session file |
| `asUser-test-sh.sh` | `TestSuite/` | `asUser` also forwards `WAYLAND_DISPLAY` (same as `newPc/setup.sh`) |

## Must stay in sync

The sudo rules in `enable_sudo_whitelist.sh` must match, character by character, the commands in:
- `sysUPD` (`bash_functions_fed.sh`)
- `firewalldStatusCheck` (`startup_common_fed.sh`)

## Not in this folder because they need no change

`startup_routine.sh` (apart from the launcher rename above), `left_idx.sh`, `right_idx.sh`, `micStatus.sh`, `headset_connection.sh`, `disk_temps.py`, `pc_usage.py`, `bashrc.sh`, `bash_profile.sh`, `bash_completion.sh`, `mediainfo.sh`, the other two sudoer scripts.

## Still to confirm on the real machine

`grep -n 'TO CONFIRM' *` in this folder lists them:
- Konsole tabs (`latexSET`, `SESSION_editing`)
- KWallet folder path (`BKP_home`)
- The `.rar` progress dialog in the Nemo `extract.sh`
- KWin reloading Night Light (`night_light.sh`)
