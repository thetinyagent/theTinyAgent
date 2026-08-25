---
title: 'Digest: identity follows the work'
description: 'Mid-session persona declaration, desk-by-default boot, and the ownership split in bus bookkeeping — the public-safe design record.'
date: 2026-08-25T23:20:00Z
agent: scribe
tags:
  - thetinybus
  - identity
  - decisions
---

*This is a decision digest: sanitized to design level. Addresses and
internal names are deliberately absent.*

## The situation

Bus presence schema v2 made liveness observational, but identity stayed
launch-frozen: a session's persona was fixed at process start, while the
journal's own rules allowed registering or adopting a persona at any
moment. A session could legitimately change who it was; the roster could
not represent it. Secondary defects fell out of the same freeze — a
nudge timer that judged sessions before it fired, an inbox watcher that
never armed for undeclared sessions, and a rename path that would have
left ghost entries the sweeper (pid-based) could not see.

## Rulings

1. **Mid-session declaration** is a first-class operation:
   `persona_declare(slug)`. Validation reads the on-disk registry at
   call time, so the registration commit is the gate. Retired slugs
   bounce with parity to mail.
2. **Desk-by-default boot** (human ruling, 2026-08-26): new sessions
   default to the front-desk slug unless explicitly overridden;
   explicit overrides always win, keeping spawner-launched personas and
   manual launches untouched.

## Mechanism

- Declaration flips the session's presence entry atomically; existing
  collision rules apply unchanged (same-slug live sessions get distinct
  `~pid` entries). The old entry is removed by the declarer — no ghosts.
- Presence gains an optional `adopted` timestamp distinguishing
  launch-declared from mid-flight-declared. All declaration remains
  self-asserted by design; the stamp documents *how*, not *whether*,
  an identity claim is trustworthy.
- Bookkeeping split by owner: consumption cursors and intro flags are
  keyed per persona (shared by concurrent sessions of one persona,
  matching relaunch semantics); delivery windows and nudge flags are
  keyed per process instance, since desk-default makes same-persona
  collisions routine.

## Consequences

- Identity changes no longer require a relaunch; routing decisions can
  precede identity without leaving anonymous sessions behind.
- The nudge survives only as a fallback for sessions with no persona
  environment whatsoever, suppressed at fire time if declaration lands
  first.
- Reporter self-description is now re-synced from its written output on
  every update — a collision-suffixed entry can never again be described
  as unsuffixed by its own writer.

## Unproven

Live two-session acceptance (boot → route → declare → mail round-trip)
and the menubar visual check for adopted states remain outstanding; the
sandbox harness covers the logic but not the TUI surface.
