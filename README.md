# Highlight.spoon

Lightweight window highlight helper for Hammerspoon. Whenever the focused window changes, the spoon draws a configurable overlay border so you can instantly see which window will receive keyboard input, handy when juggling spaces, displays, or full-screen apps.

## Requirements

- macOS with [Hammerspoon](https://www.hammerspoon.org)
- Access to the `hs.window`, `hs.window.filter`, `hs.drawing`, and `hs.timer` extensions (bundled with Hammerspoon)

## Installation

Download or clone this repository into `~/.hammerspoon/Spoons/Highlight.spoon`. Include the spoon in your `~/.hammerspoon/init.lua`:

   ```lua
   hs.loadSpoon("Highlight")
   ```

If you use [SpoonInstall](https://www.hammerspoon.org/docs/hs.spoons.html#use):

```lua
hs.loadSpoon("SpoonInstall")

spoon.SpoonInstall.repos.Highlight = {
    url = "https://github.com/Aites/Highlight.spoon",
    desc = "Highlight.spoon repository",
    branch = "main",
}

spoon.SpoonInstall:andUse("Highlight", {
    repo = "Highlight",
    config = {},
    start = true,
})
```

## Usage

Basic usage highlights the currently focused window with the default styling:

```lua
spoon.Highlight:start()
```

You can chain `configure` to override defaults before starting:

```lua
spoon.Highlight
  :configure({
    highlightBorderColor = { red = 0.99, green = 0.43, blue = 0.12, alpha = 0.95 },
    highlightBorderWidth = 6,
    highlightCornerRadius = 20,
    highlightDuration = 0.6,
    windowFilterRules = {
      ["Google Chrome"] = { allowTitles = { "Meeting" } }, -- only highlight matching windows
    },
  })
  :start()
```

Call `spoon.Highlight:stop()` to remove the highlight overlay and unsubscribe from window events. You can restart at any time with `:start()`.

## Configuration Reference

All fields match `Highlight.defaults` in `init.lua`. You only need to provide the values you want to override.

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `highlightBorderPadding` | `number` | `1` | Pixels to extend the border rectangle beyond the window frame. |
| `highlightDuration` | `number` | `1` | Seconds before the border begins fading out. |
| `highlightFadeInDuration` | `number` | `0.1` | Fade-in animation duration when a new window is highlighted. |
| `highlightFadeOutDuration` | `number` | `0.3` | Fade-out animation duration once the timer expires. |
| `highlightBorderColor` | `table` | `{ red = 1, green = 0.65, blue = 0.2, alpha = 0.95 }` | RGBA color used for the overlay stroke. |
| `highlightBorderWidth` | `number` | `3` | Stroke width in points. |
| `highlightCornerRadius` | `number` | `15` | Corner radius for the rounded rectangle. |
| `windowFilterRules` | `table \| nil` | `nil` | Rules table passed to `hs.window.filter.new`. Use this to ignore or include specific apps, titles, spaces, etc. |
| `windowFilterSubscribeEvents` | `table` | `{ hs.window.filter.windowFocused }` | List of events that should trigger a highlight. Supply values from `hs.window.filter`. |

## API

- `Highlight:configure(options)` – merge overrides into the existing configuration.
- `Highlight:init()` – ensure defaults are applied (run automatically by `:start()`).
- `Highlight:start()` – activate the spoon, subscribe to filter events, and highlight the current window.
- `Highlight:stop()` – unsubscribe and clear any active drawings.
- `Highlight:highlight(window)` – manually highlight a specific `hs.window` (falls back to the focused window).

Refer to `docs.json` (generated with `hs.doc.builder`) or inline annotations in `init.lua` for the complete documentation.

## Development

Clone the repo, make your changes, then reload Hammerspoon with `hs.reload()` to test. `docs.json` can be regenerated with `hs.doc.builder` if you update the API docs.

## License

MIT © Aietes
