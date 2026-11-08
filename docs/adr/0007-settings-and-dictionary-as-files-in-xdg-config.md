# ADR 7: Settings and Dictionary Are Files Under `~/.config/sokki`

Date: 2026-11-08

## Status

Accepted

## Context

Settings could live in `UserDefaults` (invisible, not diffable, not in dotfiles), in `~/Library/Application Support/Sokki/` (the macOS convention, required for sandboxed apps), or in `$XDG_CONFIG_HOME/sokki` (the convention of developer tools, where dotfile repositories already sync). Supporting two locations means precedence rules, two watchers, and ambiguity about which file the settings window writes. The app is not sandboxed and not sold through the App Store (ADR 8). Formats with comments (JSONC, TOML) have no writer in Foundation, so a settings UI that writes them would drop the comments anyway.

## Decision

We will keep two plain files in `$XDG_CONFIG_HOME/sokki` (default `~/.config/sokki`) and nowhere else: `config.json`, a strict-JSON object with every setting, and `dictionary.json`, a strict-JSON object mapping each replacement to the spoken forms that should become it. The app watches the directory and reloads within about 200 ms of a change; a malformed file leaves the previous values in effect and shows a warning in the menu. The settings window edits `config.json`; it has no state of its own. The app writes `dictionary.json` only to append an entry, and writes both files with sorted keys so diffs stay small.

## Consequences

Positive: settings travel with dotfiles and are diffable; the UI and the file cannot disagree; "show defaults" is generated from the same struct that reads the file, so it cannot drift.

Negative: comments are impossible in strict JSON; moving to an App Store or sandboxed build would require a different location; users who expect `~/Library/Application Support` have to be told where to look (the menu has "Open Config File").

Neutral: the menu bar is the only place the file location is shown; nothing in the app depends on the home directory layout beyond the XDG variable.
