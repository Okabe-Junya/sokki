# ADR 6: No Language Model in the Dictation Path

Date: 2026-11-08

## Status

Accepted

## Context

Raw transcripts contain fillers, self-corrections ("いや違う", "no wait"), stray spaces at segment boundaries, and katakana renderings of English terms (ADR 3). A language model is the obvious tool for this cleanup. The budget from key release to inserted text is 400 ms at p95; the pipeline without cleanup already measures 123 to 160 ms.

On-device models were measured on the reference machine. The system Foundation Models framework took 2.7 to 27 s per utterance and sometimes answered the text or translated it instead of cleaning it. 3 to 4B-parameter models under MLX took 0.84 to 1.33 s for 64 Japanese characters and did not handle self-corrections zero-shot. Output length roughly equals input length, so generation speed, not model quality, is the floor. Meanwhile every needed correction is expressible as a rule on trigger words and character classes, and such rules can be tested against a golden set with zero latency.

## Decision

We will keep the release-to-insert path free of generative models. Cleanup is a deterministic, ordered pipeline (whitespace, fillers, self-correction, personal dictionary) in the `Cleanup` module, verified by golden tests. The personal dictionary is the user's tool for term spellings. A separate, explicitly slow "rewrite" gesture may host a model later behind a `Polisher` boundary; it is not part of v1.

## Consequences

Positive: latency is unchanged by cleanup; behaviour is reproducible and unit-tested; no model download or resident memory.

Negative: rules miss what they were not written for; a filler or correction phrasing outside the list passes through unchanged, and users fix recognition errors by adding dictionary entries rather than by the app learning.

Neutral: revisit when an on-device model handles Japanese self-correction in under one second warm; the boundary for it already exists.
