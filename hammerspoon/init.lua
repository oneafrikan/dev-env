-- ─────────────────────────────────────────────
-- hammerspoon/init.lua
-- Symlinked from ~/.hammerspoon/init.lua
-- ─────────────────────────────────────────────

local DEV_ENV = os.getenv("HOME") .. "/.dev-env"

-- ── Helpers ───────────────────────────────────

local function switchContext(space, contextName)
  -- Switch macOS Space
  hs.spaces.gotoSpace(space)

  -- Alert
  hs.alert.show("→ " .. contextName, 1.5)

  -- Open a new iTerm2 tab running the context script
  local script = DEV_ENV .. "/contexts/" .. contextName .. ".sh"
  hs.task.new("/usr/bin/osascript", nil, {
    "-e", string.format([[
      tell application "iTerm2"
        tell current window
          create tab with default profile
          tell current session
            write text "ctx %s"
          end tell
        end tell
      end tell
    ]], contextName)
  }):start()
end

-- ── Context hotkeys ───────────────────────────
-- One binding per contexts/<name>.sh script. Add your own here — the
-- Space number just needs to match whatever you've set that context to
-- use (System Settings → Desktop & Dock → Spaces, or Mission Control).
--
-- Example: Ctrl+Shift+J → Space 2 → contexts/example.sh
--
-- hs.hotkey.bind({"ctrl", "shift"}, "J", function()
--   switchContext(2, "example")
-- end)

-- ── Reload config ─────────────────────────────
hs.hotkey.bind({"ctrl", "shift"}, "R", function()
  hs.reload()
  hs.alert.show("Hammerspoon reloaded", 1)
end)

-- ── Startup notice ────────────────────────────
hs.alert.show("Hammerspoon loaded", 1)
