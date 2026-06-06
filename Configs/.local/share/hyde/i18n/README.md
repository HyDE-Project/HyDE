# HyDE i18n language packs

This directory contains lightweight JSON language packs for user-facing HyDE runtime strings.

Language files use a flat key-value structure:

```json
{
  "common.error": "Error"
}
```

## Language selection

HyDE resolves the active language in this order:

```text
HYDE_LANG > I18N_LANGUAGE > LC_MESSAGES > LANG > en
```

This directory provides the shared language packs and loaders. Runtime scripts still need to
adopt the loaders before their strings become localized.

For scripts that use these loaders, users can temporarily override the language for one command:

```shell
HYDE_LANG=zh_CN example-script
HYDE_LANG=en example-script
```

Long-term configuration can be set in `~/.config/hyde/config.toml`:

```toml
[i18n]
language = "zh_CN"
```

Leave `language` empty to auto-detect from the environment.

## Guidelines

- Translate user-facing help, notifications, menu labels, tooltips, and error descriptions.
- Do not translate command names, flags, configuration keys, environment variables, paths, or internal identifiers.
- Keep all language packs on the same key set as `en.json`.
- If Chinese text renders as boxes in Rofi, Waybar, or notifications, configure a UI font with CJK glyph coverage instead of changing HyDE theme logic.
