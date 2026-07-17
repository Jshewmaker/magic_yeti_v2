# Fonts

`NunitoSans-*.ttf` are **static instances cut from the Nunito Sans variable
font**, not the files Google Fonts hands you. They are generated, so don't hand-edit them.

## Why not just ship the variable font?

**Flutter does not drive a variable font's `wght` axis from
`TextStyle.fontWeight` — only from `fontVariations`.** Verified empirically on
Flutter 3.38.4 by rendering the variable font at w200/w400/w700/w900 and
measuring: all four came out at *identical* width (844.128px for the same
string), while `FontVariation('wght', n)` moved it as expected (844.128 →
862.486 → 883.200).

That matters more than it sounds, because **Nunito Sans's `wght` axis defaults
to 200 — ExtraLight, not Regular**. Its internal name is literally
"Nunito Sans 12pt ExtraLight". Ship the variable file and the entire app renders
hairline-thin, every weight in `UITextStyle` collapses into one, and all ~38
`fontWeight` call sites across the app become dead code that no test would catch.

The alternative was a `withWeight()` helper setting `fontWeight` and
`fontVariations` together, plus converting every call site — but that leaves a
permanent trap: any future `copyWith(fontWeight: ...)` silently does nothing.
Static instances just make `fontWeight` behave the way every Flutter developer
already expects.

## Which weights, and why these

They mirror the Teko set these replaced (300/400/500/600/700), so font
resolution is unchanged by the swap: `w800`/`w900` still fall back to 700
exactly as they did before. Italic ships at 400 only — the app's two italic call
sites (`lib/friends_list/search_user/search_user_page.dart`) use the ambient
weight.

The full set is ~676K, versus ~1.4M for the five Teko files it replaced.

## Regenerating

Download the Nunito Sans variable fonts from Google Fonts
(`NunitoSans[YTLC,opsz,wdth,wght].ttf` and the matching Italic), drop them in
this directory, then with `fonttools` installed (`pip install fonttools`):

```python
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

ROMAN  = {"Light": 300, "Regular": 400, "Medium": 500, "SemiBold": 600, "Bold": 700}
ITALIC = {"Italic": 400}

def build(src, out, wght):
    f = TTFont(src)
    # Pin EVERY axis. Leaving wdth/opsz/YTLC variable keeps the font variable
    # and re-opens the fontWeight-is-ignored problem this exists to solve.
    f = instancer.instantiateVariableFont(
        f, {"wght": wght, "wdth": 100, "opsz": 12, "YTLC": 500}
    )
    f["OS/2"].usWeightClass = wght
    f.save(out)

for name, w in ROMAN.items():
    build("NunitoSans-Variable.ttf", f"NunitoSans-{name}.ttf", w)
for name, w in ITALIC.items():
    build("NunitoSans-Italic-Variable.ttf", f"NunitoSans-{name}.ttf", w)
```

Then delete the variable source files — shipping them alongside the instances
would add ~1.1M of assets nothing references.

`test/src/typography/app_ui_text_style_test.dart` guards all of this. It asserts
light < regular < bold by measuring rendered width, so a regression back to the
variable font fails the suite. Note it registers the fonts from disk with
`FontLoader`: `flutter test` does **not** load pubspec font assets and silently
falls back to Ahem, whose glyphs are fixed squares — under Ahem every weight
measures identically and the test would pass while proving nothing. That's why
there's an explicit "did we escape Ahem" assertion.
