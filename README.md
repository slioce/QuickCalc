# QuickCalc

A menu bar calculator for macOS. Type an expression and the result appears as you type: arithmetic, percentages, functions, programmer math, unit and currency conversions. Press Return and the result is on your clipboard.

```
1250*1.22                 1 525
200+10%                     220
5 km in mi     3.10685596119 mi
100 USD in EUR        89.16 EUR
```

## Features

- **Results as you type**, in a small panel that opens from the menu bar or with ⌃⌥Space from any app, without taking focus away from the app you are in.
- **Everyday math**: + − × ÷, powers, parentheses, and percentages the way a desk calculator does them (`200+10%` is 220). The previous result is `ans`, and an expression that starts with an operator (`+22%`) continues from it.
- **Functions**: roots, trigonometry in radians or degrees (`sin(30°)`), logarithms, rounding, min and max, factorial.
- **Programmer math**: hex, binary and octal literals, bitwise operators and shifts on 64-bit integers, and conversion with `in hex`, `in bin`, `in oct`, `in dec`.
- **Unit conversions** across length, mass, time, temperature, volume, area, speed, data, energy, pressure and power: `1 m3 in l`, `30°C in F`, `100 CV in kW`.
- **Currency conversions** at the European Central Bank's daily reference rates, for about 30 currencies, cached for offline use.
- **Both decimal conventions**: `2,5` and `2.5` are both understood; results use your region's decimal separator.
- **History** of confirmed results, recalled with ↑ and ↓.
- **Built-in guide** listing every operation with an example to try; type `?` to open it.
- Localized in English and Italian.
- Sandboxed, under 1.5 MB on disk and around 15 MB of memory.

## Requirements

macOS 15 or later, on Apple Silicon or Intel.

## Usage

Click the menu bar icon or press ⌃⌥Space, type an expression, and read the result below it.

- **Return** copies the result, adds it to the history and clears the field.
- **⌘C** with no text selected, the copy icon or a click on the result copy it and keep the expression.
- **↑ ↓** recall previous expressions; click a line of the history to copy its result.
- **Esc** closes the guide, then the panel.

Right-click the icon for **Help**, **Launch at Login**, **Clear History**, **About** and **Quit**.

QuickCalc follows the language of macOS. To use it in another language, choose one for QuickCalc in System Settings › General › Language & Region › Applications.

## What you can type

| Example | Result |
|---|---|
| `1250*1.22` · `(2+3)*4` · `2^10` · `7 mod 3` · `5!` | arithmetic, power, remainder, factorial |
| `200+10%` · `200-15%` · `80*5%` | 220 · 170 · 4 |
| `+22%` · `ans*2` | continue from the previous result |
| `2pi` · `3(4+1)` · `√16` · `3²` | implicit multiplication, root, square and cube |
| `sin(30°)` · `log(8; 2)` · `round(3.14159; 2)` · `max(2; 7; 3)` | functions; arguments are separated by `;` |
| `0xFF & 0b1111 in hex` · `-1 in bin` · `1 << 4` | 64-bit integers: `& \| xor ~ << >>` |
| `5 km in mi` · `1 m3 in l` · `30°C in F` | units, with `in` or `to` |
| `100 USD in EUR` · `$100 in €` · `50 dollars to GBP` | currencies, at the day's ECB rate |

**Numbers.** `2,5` and `2.5` are the same number. A lone comma followed by three digits depends on your region: with a decimal comma `1,234` is one point two three four, with a decimal point it is one thousand two hundred thirty-four. Repeat the separator or use both to group thousands: `1.000.000`, `1,234.5`. Results group thousands with a thin space, which QuickCalc reads back when you paste them.

**Functions**: `sqrt cbrt abs sin cos tan asin acos atan sinh cosh tanh ln log log2 exp floor ceil round min max`. **Constants**: `pi π e tau ans`. Angles are in radians; add `°` for degrees.

**Units**: length `nm µm mm cm dm m km in ft yd mi nmi` · mass `mg g kg q t oz lb` · time `ms s min h d wk yr` · temperature `C F K` · volume `mm3 ml cm3 cc cl dl l dm3 hl m3 tsp tbsp floz cup pt qt gal in3 ft3` · area `mm2 cm2 m2 km2 ha in2 ft2 yd2 acre mi2` · speed `m/s km/h ft/s mph kn` · data `bit kbit Mbit Gbit B KB MB GB TB KiB MiB GiB TiB` · energy `J kJ cal kcal Wh kWh BTU` · pressure `Pa hPa mbar kPa bar MPa atm psi mmHg` · power `W kW MW CV hp`. Exponents can also be written `m²`, `m³`. Customary units are the US ones.

**Currencies**: the codes the ECB publishes (`EUR USD GBP CHF JPY CNY CAD AUD SEK NOK DKK PLN CZK HUF RON…`), the symbols `€ $ £ ¥`, and names such as `euros`, `dollars`, `sterling`. Results are rounded to the cent and show the date of the rates.

## Build from source

Requires Xcode 16 or later.

```sh
git clone https://github.com/slioce/QuickCalc.git
cd QuickCalc
make install   # builds, copies to /Applications and launches
make run       # launches the build without installing it
make test      # runs the engine tests
```

Or open `QuickCalc.xcodeproj` in Xcode and press Run. The project is signed to run locally out of the box; no developer account is needed. Launch at Login only works for a copy in a stable location such as `/Applications`, so test it after `make install`.

## Project layout

```
QuickCalc/              The app: menu bar item, panel, guide, history, hotkey, exchange rates. AppKit only, no SwiftUI.
QuickCalc/Resources/    Info.plist, entitlements, privacy manifest, icon, localizations.
QuickCalcCore/          Swift package with the expression engine, units and currencies, and their tests. No AppKit, no UI.
Config/                 Build settings shared by every configuration (xcconfig).
scripts/                make-icon.swift draws the app icon set.
```

The engine is a small recursive-descent parser over `Double`, with results rounded to 12 significant digits for display. `Calculator.evaluate("5 km in mi")` returns the value, the text to show and the text to copy; when there is no result it throws a `CalcError`, which the app turns into a message. The guide's examples live in the engine too, and the tests run every one of them.

## Publishing to the App Store

1. Create `Config/Local.xcconfig` (ignored by git) with your team:

   ```
   DEVELOPMENT_TEAM = ABCDE12345
   CODE_SIGN_IDENTITY = Apple Development
   ```

2. In Xcode, choose Product › Archive (or run `make archive`), then Distribute App › App Store Connect.

The app runs in the App Sandbox with one entitlement, `com.apple.security.network.client`, used to download the exchange rates. The global shortcut uses Carbon's `RegisterEventHotKey`, which needs no Accessibility permission. The privacy manifest declares the one required-reason API the app uses: user defaults, for the history and the cached rates.

## Privacy

Calculations and history stay on your Mac. The only network request downloads the European Central Bank's public reference rates, at most a few times a day; it sends no data about you or your calculations. QuickCalc collects no data, and the privacy manifest (`PrivacyInfo.xcprivacy`) declares no tracking and no collected data.

## Acknowledgements

Exchange rates are the euro foreign exchange reference rates published by the European Central Bank. QuickCalc was written with the help of AI coding agents; design, review and testing are the author's.

## License

Copyright © 2026 Alessandro Lioce. QuickCalc is free software, released under the [GNU General Public License v3.0](LICENSE) or any later version.
