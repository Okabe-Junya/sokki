# ADR 12: Push-to-Talk on a Recorded Modifier Chord

Date: 2026-11-09

## Status

Accepted

Supersedes ADR 4.

## Context

ADR 4 limited the hotkey to one modifier from a fixed list of four. In practice another tool already claims double-tapping right Option, and the remaining presets do not suit every keyboard or habit, so users want to pick their own combination. The constraints behind ADR 4 still hold: during secure input the system withholds key-down and key-up of ordinary keys but still delivers `flagsChanged`, and the listen-only event tap cannot swallow a key, so an ordinary key in the hotkey would also be typed into the frontmost app. A chord made only of modifier keys avoids both problems. Each modifier has a left and a right device bit, so a chord can name sides exactly. Event flags also carry bits that are not held modifiers: Caps Lock, the numeric-pad bit, and on laptop keyboards the fn flag that arrow and function keys set. Holding a modifier while typing is normal (Shift for capitals, Option or Control in shortcuts), so a press that turns into a shortcut right away is not a dictation.

## Decision

The hotkey is a non-empty set of side-specific modifier keys (left or right Control, Option, Shift, Command, and fn), recorded in Settings by holding the keys and releasing them. A chord made only of Shift keys cannot be recorded. The chord counts as down when every key in the set is down and no other modifier is, where "other modifier" means a device bit of Control, Option, Shift, or Command outside the set, and the fn flag only when fn is in the set; Caps Lock and the other flag bits are ignored. The chord counts as up when any of its keys is released. The state machine of ADR 4 is unchanged otherwise: a press under 300 ms is ignored, a longer hold dictates until release, two short presses within 300 ms lock a hands-free session that the next press ends, and Escape discards. One rule is added: an ordinary key, or a modifier outside the set, pressed within the first 300 ms of a press cancels that press at once, so shortcuts that start with the chord do not dictate; after 300 ms the press is a dictation and such keys are ignored. `config.json` stores the chord as one string of key names joined by `+` (`"leftControl+leftOption"`); the existing single names are valid chords of one key. Ordinary keys stay out of the hotkey.

## Consequences

Positive: users can avoid conflicts with other tools without leaving the modifier-only model; existing config files keep working and the value stays a string in the file and in the activity log; the hotkey still works during secure input and still never reaches the frontmost app as a typed character.

Negative: a chord is harder to double-tap than one key; every chord-down starts the microphone and recognizer, also when the keys turn out to be a shortcut prefix; releasing the chord one key at a time delays the paste until every modifier is up, and the paste fails after 500 ms of a modifier still held (ADR 5); the recorder needs the Settings window to be key to observe the keys, and the running hotkey has to pause while it records.

Neutral: the event tap, the Input Monitoring permission, and the timing constants are unchanged; the four previous presets are valid chords of one key; Sticky Keys latches modifiers and is not supported; holding one key of a chord and tapping the other twice counts as a double-tap.
