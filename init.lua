--- === Highlight ===
---
--- Lightweight window highlight helper for Hammerspoon.
---
local Highlight = {}
Highlight.__index = Highlight

Highlight.name = "Highlight"
Highlight.version = "0.2.0"
Highlight.author = "Aietes"
Highlight.homepage = "https://github.com/aietes/Highlight.spoon"
Highlight.license = "MIT"

local Window <const> = hs.window
local WindowFilter <const> = Window.filter
local Drawing <const> = hs.drawing
local Timer <const> = hs.timer

Highlight.defaults = {
  highlightBorderPadding = 1,
  highlightDuration = 1,
  highlightFadeInDuration = 0.1,
  highlightFadeOutDuration = 0.3,
  highlightBorderColor = { red = 1, green = 0.65, blue = 0.2, alpha = 0.95 },
  highlightBorderWidth = 3,
  highlightCornerRadius = 15,
  windowFilterRules = nil,
  windowFilterSubscribeEvents = { WindowFilter.windowFocused },
}

Highlight.logger = hs.logger.new("Highlight", "info")

local function shallowCopy(source)
  if source == nil then
    return nil
  end
  local target = {}
  for key, value in pairs(source) do
    target[key] = value
  end
  return target
end

--- Highlight:configure(options)
--- Method
--- Applies configuration overrides (border appearance, display timings, filter rules, subscription events).
---
--- Parameters:
---  * options - Table matching the keys in `Highlight.defaults`.
---
--- Returns:
---  * Highlight - The spoon instance (for chaining).
function Highlight:configure(options)
  local opts = options or {}
  local config = self.config or {}

  config.highlightBorderPadding = opts.highlightBorderPadding or config.highlightBorderPadding
      or self.defaults.highlightBorderPadding
  config.highlightDuration = opts.highlightDuration or config.highlightDuration or self.defaults.highlightDuration
  config.highlightFadeInDuration = opts.highlightFadeInDuration or config.highlightFadeInDuration
      or self.defaults.highlightFadeInDuration
  config.highlightFadeOutDuration = opts.highlightFadeOutDuration or config.highlightFadeOutDuration
      or self.defaults.highlightFadeOutDuration

  local color_override = opts.highlightBorderColor or {}
  local existing_color = config.highlightBorderColor or self.defaults.highlightBorderColor
  config.highlightBorderColor = {
    red = color_override.red or existing_color.red or self.defaults.highlightBorderColor.red,
    green = color_override.green or existing_color.green or self.defaults.highlightBorderColor.green,
    blue = color_override.blue or existing_color.blue or self.defaults.highlightBorderColor.blue,
    alpha = color_override.alpha or existing_color.alpha or self.defaults.highlightBorderColor.alpha,
  }

  config.highlightBorderWidth = opts.highlightBorderWidth or config.highlightBorderWidth
      or self.defaults.highlightBorderWidth
  config.highlightCornerRadius = opts.highlightCornerRadius or config.highlightCornerRadius
      or self.defaults.highlightCornerRadius
  config.windowFilterRules = opts.windowFilterRules or config.windowFilterRules or self.defaults.windowFilterRules
  config.windowFilterSubscribeEvents = shallowCopy(opts.windowFilterSubscribeEvents)
      or shallowCopy(config.windowFilterSubscribeEvents)
      or shallowCopy(self.defaults.windowFilterSubscribeEvents)

  self.config = config
  return self
end

--- Highlight:init()
--- Method
--- Ensures defaults are applied before the spoon is used.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Highlight
function Highlight:init()
  if self.config == nil then
    self:configure({})
  end
  return self
end

--- Highlight:start()
--- Method
--- Marks the spoon as active, subscribes to window focus events, and immediately highlights the focused window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Highlight
function Highlight:start()
  self:init()
  self.active = true
  self:_setupWindowFilter()
  self:highlight()
  return self
end

--- Highlight:stop()
--- Method
--- Clears any pending highlight drawings, unsubscribes from window events, and deactivates the spoon.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Highlight
function Highlight:stop()
  self.active = nil
  self:_teardownWindowFilter()
  self:_reset()
  return self
end

function Highlight:_stopTimers()
  if self.clearTimer ~= nil then
    self.clearTimer:stop()
    self.clearTimer = nil
  end
  if self.fadeTimer ~= nil then
    self.fadeTimer:stop()
    self.fadeTimer = nil
  end
end

function Highlight:_deleteDrawing()
  if self.borderDrawing ~= nil then
    self.borderDrawing:delete()
    self.borderDrawing = nil
  end
  if self.fadingBorderDrawing ~= nil then
    self.fadingBorderDrawing:delete()
    self.fadingBorderDrawing = nil
  end
end

function Highlight:_reset()
  self:_stopTimers()
  self:_deleteDrawing()
end

function Highlight:_fadeOut()
  self:_beginFadeOutActiveDrawing()
end

function Highlight:_beginFadeOutActiveDrawing()
  if not self.borderDrawing then
    return
  end

  if self.clearTimer then
    self.clearTimer:stop()
    self.clearTimer = nil
  end

  local drawing = self.borderDrawing
  self.borderDrawing = nil

  if self.fadeTimer then
    self.fadeTimer:stop()
    self.fadeTimer = nil
  end

  if self.fadingBorderDrawing ~= nil then
    self.fadingBorderDrawing:delete()
    self.fadingBorderDrawing = nil
  end

  local fade_duration <const> = self.config.highlightFadeOutDuration
  drawing:show()
  drawing:hide(fade_duration)

  self.fadingBorderDrawing = drawing
  self.fadeTimer = Timer.doAfter(fade_duration, function()
    if self.fadingBorderDrawing == drawing then
      drawing:delete()
      self.fadingBorderDrawing = nil
    else
      drawing:delete()
    end
    self.fadeTimer = nil
  end)
end

function Highlight:_drawWindow(window)
  local target = window or Window.focusedWindow()
  if not target then
    self:_fadeOut()
    return
  end

  local frame <const> = target:frame()
  local padding <const> = self.config.highlightBorderPadding
  local rect = {
    x = frame.x - padding,
    y = frame.y - padding,
    w = frame.w + (padding * 2),
    h = frame.h + (padding * 2),
  }

  if self.borderDrawing then
    self:_beginFadeOutActiveDrawing()
  end

  local drawing = Drawing.rectangle(rect)
  if drawing == nil then
    self.logger.e("Failed to create drawing for window highlight")
    return
  end

  drawing:setLevel("overlay")
  drawing:setStroke(true)
  drawing:setStrokeColor(self.config.highlightBorderColor)
  drawing:setStrokeWidth(self.config.highlightBorderWidth)
  drawing:setRoundedRectRadii(self.config.highlightCornerRadius, self.config.highlightCornerRadius)
  drawing:setFill(false)
  drawing:show(self.config.highlightFadeInDuration)

  self.borderDrawing = drawing
  self.clearTimer = Timer.doAfter(self.config.highlightDuration, function()
    if self.borderDrawing == drawing then
      self:_fadeOut()
    end
  end)
end

function Highlight:_setupWindowFilter()
  self:_teardownWindowFilter()
  local rules = self.config.windowFilterRules
  local filter
  if rules == nil then
    filter = WindowFilter.new()
  else
    filter = WindowFilter.new(rules)
  end

  filter:subscribe(self.config.windowFilterSubscribeEvents, function(window)
    self:highlight(window)
  end)
  self.windowFilter = filter
end

function Highlight:_teardownWindowFilter()
  if self.windowFilter ~= nil then
    self.windowFilter:unsubscribeAll()
    self.windowFilter = nil
  end
end

--- Highlight:highlight(window)
--- Method
--- Draws a border around the supplied window (or the focused window if omitted). Automatically invoked when focus changes.
---
--- Parameters:
---  * window - Optional `hs.window` instance.
---
--- Returns:
---  * Highlight
function Highlight:highlight(window)
  if self.active == nil then
    self.logger.w("Highlight not started, ignoring highlight request")
    return self
  end
  self:_drawWindow(window)
  return self
end

return Highlight
