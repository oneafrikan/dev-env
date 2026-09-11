# iTerm2 per-machine profiles

Every machine gets an iTerm2 profile with a distinct background color, so a
glance at the terminal tells you which box you're on — no reading hostnames
in the prompt required.

## How it works

iTerm2's [Dynamic Profiles](https://iterm2.com/documentation-dynamic-profiles.html)
feature auto-loads any `.json` file dropped in
`~/Library/Application Support/iTerm2/DynamicProfiles/`, live-reloading on
change (no restart needed). `setup.sh` symlinks the right file in from here,
based on `hostname -s`.

`profiles/*.json` isn't included in this repo — it's machine-specific by
definition. `profiles/example.json` shows the shape; copy it to
`profiles/<your-hostname>.json` and edit the `Guid`, `Name`, and
`Background Color (Dark)` / `Background Color` fields.

Pick colors that avoid semantic clashes: red usually means "error"/"deletion"
in git diffs and linters, and deep purple tends to read as muddy against ANSI
magenta text — safer to pick clearly distinct hues elsewhere on the wheel.

If a manually-created profile already exists in iTerm2 for that machine, reuse
its `Guid` in your JSON — dropping the file then takes over that profile in
place instead of creating a duplicate. Find existing Guids in iTerm2's
Preferences → Profiles, or in `~/Library/Preferences/com.googlecode.iterm2.plist`.

## Setup on a new machine

```bash
bash ~/.dev-env/scripts/iterm2-profiles/setup.sh
```

Detects the machine name from `hostname -s`. Pass a name explicitly to
override: `setup.sh my-server`.

## Adding a machine

1. Copy `profiles/example.json` to `profiles/<machine>.json` — set `Guid`
   (generate with `uuidgen`), `Name`, `Description`, and
   `Background Color (Dark)` / `Background Color`.
2. Run `setup.sh` on that machine.
