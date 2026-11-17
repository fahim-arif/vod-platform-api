# 0003. Playable supertype for movies and episodes

- Status: Accepted
- Date: 2026-11-17

## Context

Assets, watch progress and availability windows must point at "something playable." That can be a movie or an episode and those live in different tables (movie_details and episode).

A foreign key can only reference one table, so pointing at "a movie or an episode" is a polymorphic association. I want to avoid it.

## Options considered

A: Two nullable foreign keys (movie and episode) on every referencing table, plus a check that exactly one is set. Works but repeats the polymorphic workaround in every table that refers to playable content.

B: A playable table holding the two nullable foreign keys (movie_title_id, episode_id) and everything else points at playable. The workaround lives in only one table and a playable can never be orphaned. But it is still the polymorphic workaround and each new playable kind adds another nullable column.

C: A playable supertype that movies and episodes point at. Every movie and episode has exactly one playable row and everything else points at playable with one ordinary foreign key. Same pattern as ADR 0002.

## Decision

We are choosing C with the same composite foreign key pattern as ADR 0002. Playable has a kind (MOVIE or EPISODE) and UNIQUE (id, kind). movie_details and episode each store playable_id and playable_kind with playable_kind locked to their own kind by a check constraint and reference playable by (id, kind). playable_id is NOT NULL and UNIQUE on both sides.

Playable is internal and has no public ID. Clients request titles and episodes and the server resolves the playable.

## Consequences

Positive:

- Assets, watch progress and availability windows each need one foreign key, to playable.
- The database rejects a movie and an episode sharing one playable, and two movies (or two episodes) sharing one.
- One pattern across the schema: ADRs 0002 and 0003 use the same supertype-plus-composite-key design.

Negative:

- Creating a movie takes three inserts (title, movie_details, playable) and an episode takes two (episode, playable).
- An extra playable_kind column on movie_details and episode, plus raw SQL check constraints in a migration, as in ADR 0002.
- Reaching a movie or episode from a playable needs a join through the referencing table.

Obligations:

- The database cannot stop a playable from having no movie or episode pointing at it. A movie or episode and its playable are created in the same transaction. An orphaned playable is unreachable, so the risk is low.

Revisit if: a new kind of playable content appears (standalone trailers, live events). It needs a new enum value and a new referencing column on that table but nothing that points at playable changes.
