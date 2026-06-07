# HyDE Runtime Localization

HyDE uses gettext `.po` files as the editable source for runtime translations.
Generated `.mo` files are used by Python and other gettext consumers, while Bash
loads a small generated associative-array map from the same `.po` file.

## Language selection

Force Simplified Chinese:

```sh
HYDE_LANG=zh_CN hyde-shell keybinds_hint
```

Force English:

```sh
HYDE_LANG=en hyde-shell keybinds_hint
```

Language resolution checks `HYDE_LANG`, `I18N_LANGUAGE`, `LC_MESSAGES`, and
`LANG`, then falls back to English/original strings.

## Regenerating files

After editing `Source/locale/zh_CN/LC_MESSAGES/hyde.po`, regenerate runtime
translation files:

```sh
python3 Source/locale/build.py
```

The script uses standard gettext tools when available:

- `xgettext` updates `Source/locale/hyde.pot`
- `msgmerge` updates `.po` files from the template
- `msgfmt` compiles `.po` files into `.mo`

It also generates Bash maps such as
`Configs/.local/share/hyde/locale/zh_CN.sh`.

Missing translation files or missing keys safely fall back to the original
English strings.
