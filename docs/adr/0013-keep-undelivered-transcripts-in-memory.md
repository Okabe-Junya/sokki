# ADR 13: Keep Recent Transcripts in Memory and Copy Only on Request

Date: 2026-11-09

## Status

Accepted

## Context

ADR 5 inserts by pasting and restores the clipboard within about 100 ms, so the user's clipboard is never taken over. When the paste lands nowhere, because no text field has focus or secure input blocks it, the transcript is lost: the clipboard is restored and nothing is shown. Leaving the transcript on the clipboard would recover it, but it would overwrite whatever the user copied, which ADR 5 exists to prevent. Checking the focused element through the Accessibility API before pasting does not tell reliably whether a paste will land: spreadsheet cells, canvases, and terminals accept ⌘V without a text role, browsers and Electron apps report generic roles, and the calls are synchronous and can stall inside the latency budget of ADR 6. ADR 5 already has a signal after the fact: the promise provider records when an app reads the pasted text, and no read before the 1.5 s fallback means almost certainly that nothing took the paste. ADR 11 writes per-utterance metadata to disk and must never carry the transcript.

## Decision

We will keep the cleaned text of the last five utterances that reached insertion in memory, never on disk, and write one to the general pasteboard as a plain string, without the transient markers, only when the user picks it from a "Copy Recent Transcript" submenu in the status menu. When secure input blocks the paste, or no app read the pasteboard before the receipt fallback, the status icon and the top menu line say the text was not inserted and a "Copy Last Transcript" item appears, until the next dictation or copy. The transcript reaches the menu through the session observer, never through the activity log's report. The insertion path of ADR 5 is unchanged.

## Consequences

Positive: a failed insertion can be recovered without the clipboard ever holding a transcript the user did not ask for; secure-input blocks and unread pastes become visible.

Negative: an unread paste is reported up to 1.5 s after release; a clipboard manager that reads the promise despite the markers makes an unread paste look inserted; transcripts in memory disappear when the app quits, and the submenu shows their beginnings to anyone who can see the screen.

Neutral: nothing new is written to disk, so the activity log and the files of ADR 7 are unaffected; re-inserting a transcript can be added later through the same `TextInserter` entry point.
