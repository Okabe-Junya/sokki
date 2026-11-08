# ADR 11: Bounded Activity Log Without Transcripts

Date: 2026-11-09

## Status

Accepted

## Context

Tuning the hotkey, locale, or dictionary needs a record of how utterances actually went: how long they were, how long finalization and insertion took, how often they were discarded, empty, silent, or blocked by secure input. The app already writes to the unified log (`os.Logger`), but `info` and `debug` messages are kept only in memory unless a configuration profile is installed with `sudo log config`, interpolated strings are redacted as `<private>`, and the system decides retention, so the history is gone before it is useful. Apple frameworks only (ADR 2) rules out logging packages. The app promises that audio and text never leave the Mac, and a file on disk is read by backup tools, sync clients, and anyone the user shares it with.

## Decision

We will append one JSON object per utterance to `~/Library/Logs/Sokki/activity.jsonl`, the per-user log location that Console shows. Each line holds the time, app version, hotkey, locale, outcome, timings, raw and cleaned character counts, peak input level, and an error description; it never holds the transcript or the audio. The file is bounded to two generations: when the next line would push it past 1 MB it is renamed to `activity.1.jsonl`, replacing the previous one, so the log never exceeds about 2 MB (several thousand utterances). Logging is always on and has no setting; a failed write is reported to the unified log and never affects dictation. The unified log stays for diagnostics.

## Consequences

Positive: the history survives restarts and can be queried with `jq`; storage is bounded without a cleanup job; the file contains nothing that would break the on-device promise if shared.

Negative: misrecognitions cannot be reviewed from the log, since the text is not there; the dictionary still has to be tuned from memory. Changing the rotation size or adding fields that carry text needs a new record.

Neutral: the log is not a user-editable file, so it lives under `~/Library/Logs` rather than in the config directory of ADR 7; deleting it is always safe.
