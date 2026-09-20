# HyDE Settings test and acceptance plan

## Automated behaviour matrix

Run `sh tests/run.sh settings`. Tests use Python's standard library and GTK/Xvfb;
no physical devices or external configuration tools are exercised.

| Boundary | Inputs / failure | Required outcome |
| --- | --- | --- |
| Search | Empty, whitespace, uppercase, full-width Unicode, multiple words | Correct global matches; all words required |
| Search | Unknown words, emoji, NUL, shell syntax, very long query | No crash, no execution, no invented match |
| CLI | Help, unknown flag, positional argument, value on boolean flag | Correct exit status and readable output; no traceback |
| Display | No Wayland/X11 connection | Exit 1 with an explanation |
| Catalogue | Every action and category | Unique entries; HyDE command exists in the checkout; fixed scope argv |
| XDG | Empty, relative and absolute path containing spaces | Standard fallback or exact absolute path |
| Probes | Missing executable, permission denied, timeout, invalid output | Missing data rather than a broken window |
| Memory | Valid, absent, negative, nonnumeric and oversized number | Correct GiB or Not available |
| GPU | Multiple synthetic PCI display controllers | Every matching controller shown |
| Version | Shell syntax in cached version | Literal display; no command execution |
| Desktop entries | Missing, valid, hidden, invalid, failing TryExec | Resolve through GIO or show unavailable |
| Launch | Tool disappears, subprocess cannot start, nonzero exit | Inline explanation and usable controls |
| CSS | Valid roles, imports and symbolic expressions | Complete palette resolves |
| CSS | Empty, missing role, invalid colour, bad syntax, missing import | Reject the entire candidate |
| CSS | Read permission failure, delete and recreate | Retain last valid palette and recover |
| Live CSS | Atomic replace, rapid successive changes | Latest valid palette wins; category and query survive |
| Navigation | Every category, global results, clearing query | Correct right-hand title and no nested pages |
| Keyboard | Ctrl+F and Escape | Search focus and return to selected category |
| Window | Repeated activation, compact width | One window; usable 650 px layout |
| Clipboard | Literal markup-like and long system values | Copy the same plain-text overview |

The GTK test writes `/tmp/hyde-settings-test.png`, containing only its isolated
window. This is a review aid, not a pixel-perfect assertion against a developer's
personal theme. Colour parsing tests intentionally include extreme palettes;
passing them is not evidence that those palettes have accessible contrast.

## Compositor and visual acceptance

These checks need a real HyDE session and must be recorded separately from unit
results. Do not label them passed based on Xvfb or synthetic hardware data.

1. Launch from the installed desktop file and Waybar menu. Launch again; the same
   window must appear. Open a theme selector, switch a theme and verify the hub
   survives Waybar reload. Test both systemd/app2unit and the documented fallback
   if a non-systemd target is supported.
2. Compare the hub with Waybar and Rofi in a fixed theme and Wallbash off, auto,
   light and dark. Switch wallpaper/theme repeatedly while search is active and
   while scrolled. Colours must converge without a restart, losing focus or
   resetting navigation. A malformed intermediate file must not flash GTK colours.
3. Check selected, hovered, pressed, disabled and keyboard-focused entries.
   Use actual composed foreground/background values to assess text contrast,
   including transparent surfaces over bright and dark wallpapers. If the theme
   fails contrast, report the theme/colour combination; do not claim compliance.
4. Check 100%, 150% and 200% display scaling and enlarged GTK fonts. Names and
   explanations must wrap rather than disappear; all controls must be reachable
   by keyboard and scrolling. Verify screen-reader names and reading order.
5. Change GTK font and icon settings while the hub is open. Verify consistent
   updates and recognisable fallback icons. Check Hyprland animations disabled,
   blur disabled and opaque window rules; navigation must remain immediate.
6. Install/remove one optional tool and revisit its category. Confirm the status
   and launch outcome. GIO startup success alone cannot detect a later application
   crash; open the tool from a terminal when diagnosing such failures.
7. Compare system overview values with local tools. On NVIDIA/AMD systems verify
   PCI identification; the hub does not collect vendor temperatures or utilization.
   Check a separate home filesystem, shared Btrfs storage and unavailable DMI.

## Regression suite and limits

Run `sh tests/run.sh` after focused tests pass. A shell runner case can contain
multiple Python tests; report both counts accurately. Missing shellcheck and
sandbox-restricted device/socket checks are skips or infrastructure limitations,
not proof of correctness. CI installs the declared GTK test dependencies in both
its test and coverage jobs.

Actual printer/scanner/controller operations require suitable devices. Mocked
launch failures and synthetic PCI data do not constitute hardware verification.

## Validation record — 2026-09-10

- Full repository suite: 49 shell-runner cases, zero failures. Its settings case
  contains nine logic tests and six GTK integration tests.
- Focused settings suite: all 15 tests passed after the live palette and
  asynchronous desktop-directory cache regressions were addressed.
- Lua syntax: all 79 shipped Lua files passed after the window-rule update.
- Pre-commit hooks for all changed/new files: passed, including Markdown, YAML,
  TOML, XML and Luacheck. Luacheck 1.2.0 required the installed Lua 5.4 interpreter;
  its source is incompatible with Lua 5.5. The check environment was temporary.
- Desktop-file validation, shell syntax and whitespace checks: passed.
- Current installed Waybar palette: loaded and visually inspected in an isolated
  GTK window. Live Wayland launch: confirmed `org.hyde.Settings` app identity and
  repeat activation without a second window.
- Infrastructure limits: shellcheck was not installed; the existing colour-pass
  test skipped its restricted character-device scenario.
- Not yet verified: the complete compositor/visual acceptance list above, real
  printer/scanner/controller operations, NVIDIA/AMD hardware, and deployment of
  the new launcher/menu/window rule through a full installer run. The checkout
  preview runs against the existing installed tools.

## Follow-up TODO

- [ ] Investigate and fix the OLED Saver shader's damage-tracking requirement:
  [HyDE-Project/HyDE#2076](https://github.com/HyDE-Project/HyDE/issues/2076).
  Deferred shader-loader work; keep the fix separate from the settings hub.
  The issue records reproduction details and the regression-test checklist.
