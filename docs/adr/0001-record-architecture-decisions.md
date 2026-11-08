# ADR 1: Record Architecture Decisions

Date: 2026-11-08

## Status

Accepted

## Context

Sokki makes a handful of choices that are expensive to reverse and surprising without their context: which speech engine runs, how the hotkey is observed, how text reaches the frontmost app, where settings live, and how the app is signed and distributed. The reasoning behind them was spread over chat logs and measurements that are not in this repository.

## Decision

We will record architecturally significant decisions as Architecture Decision Records in `docs/adr`, in the format [described by Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions): title, date, status, context, decision, consequences. One decision per file, numbered `NNNN-slug.md`. A changed decision gets a new record that supersedes the old one; old records stay as history.

## Consequences

Each record is a page or less. `.adr-dir` points [adr-tools](https://github.com/npryce/adr-tools) at the directory. Readers who want the measurements behind a decision find them in the record's context section; no other document in this repository restates them.
