# UI font profiles

`ui_font.tres` is the single font selector consumed by the authored menu themes.
It uses `ui_hd_font.tres` by default. For a pixel game, open `ui_font.tres` and
set `base_font` to `ui_pixel_font.tres`.

- `ui_hd_font.tres`: IBM Plex Sans SC Regular, a hinted screen UI face.
- `ui_pixel_font.tres`: Fusion Pixel Font 10px proportional Simplified Chinese.

Pixel text is sharpest at 10 px multiples with integer positions and integer
viewport scaling. The default flexible jam layout is optimized for the HD font;
pixel projects should also align their font sizes and viewport scale to the
font's 10 px grid.

Licenses are stored in `licenses/`. The bundled font files are unmodified:

- IBM Plex Sans SC `1.1.0`: <https://github.com/IBM/plex>
- Fusion Pixel Font `2026.07.20`: <https://github.com/TakWolf/fusion-pixel-font>

Fusion Pixel's component licenses are preserved below
`licenses/fusion-pixel/LICENSES/`. Font checksums used by this template:

- IBM Plex WOFF2: `DC51399CE38F7200806DF891476D7216A81C8AEDE47284E421A54413608C407C`
- Fusion Pixel WOFF2: `0D8D8AB1C2A289F525BACD34CFD130715CCC282715AA1270D1B72D810DB69094`
