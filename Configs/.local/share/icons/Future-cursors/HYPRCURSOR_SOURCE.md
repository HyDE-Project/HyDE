# Future Cyan Hyprcursor provenance

- Port: https://gitlab.com/Pummelfisch/future-cyan-hyprcursor
- Pinned commit: `cf4126d17f4520aceb688d8a60daca4a1f0b9e80`
- License: GNU GPL v3.0; the identical license is tracked at `dotfiles/.local/share/icons/Future-cursors/LICENSE`.
- Imported source: upstream `Future-Cyan-Hyprcursor_prebuild/` working tree.
- Original XCursor: https://github.com/yeyushengfan258/Future-cursors at `587c14d2f5bd2dc34095a4efbb1a729eb72a1d36`.

Overlay modifications:

- The manifest name is `Future-cursors`, allowing one theme identifier for native Hyprcursor and XCursor fallback clients.
- `arrow` hotspot is `0.1875, 0.125`, matching the corrected original cursor ratio `12,8` on its 64-pixel representation.
- `pointer` hotspot is `0.421875, 0.21875`, matching the corrected original cursor ratio `27,14` on its 64-pixel representation.

Build with:

```bash
hyprcursor-util --create cursor-sources/Future-cyan-hyprcursor --output /tmp/future-cursor-build
```
