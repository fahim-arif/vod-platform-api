# 0005. Unpublishing with computed visibility

- Status: Accepted
- Date: 2026-11-16

## Context
Content must be hideable without deleting it, because user data (watch history, progress, watchlists) points at it.

Each level of the catalog (title, season, episode) can be hidden on its own and hiding a parent must hide its children.

## Options considered
A: Hard delete. Simple but destroys user data that references the content.

B: Cascading status writes. Unpublishing a series sets every season and episode to unpublished. Simple to query but it destroys information. If Episode 4 is pulled on its own and then the whole series is unpublished and later republished, the database no longer knows whether Episode 4 should come back.

C: Computed visibility. Each level keeps its own status and visibility is worked out at query time from the item and all its parents.

## Decision
We are choosing C. Title, season and episode each have a status column, using one Postgres enum with three values:
- DRAFT: being prepared, never shown.
- PUBLISHED: visible.
- UNPUBLISHED: was visible, now hidden.

An item is visible only if it and all its parents are PUBLISHED. A movie is visible if its title is published; an episode is visible if the episode, its season and its series title are all published. Once availability windows exist, they become part of the same rule.

## Consequences
Positive:
- Republishing a parent restores exactly what was visible before. Individually hidden children stay hidden.
- No user data is ever deleted.
- DRAFT content has no user data pointing at it, so it can be changed freely.

Negative:
- Checking an episode's visibility means joining episode -> season -> title. These are cheap joins on indexed foreign keys but more work than reading one column.

Obligations:
- The visibility filter lives in one central place (a single repository method or Prisma client extension), so no query can forget it. One forgotten filter leaks hidden content.
- UNPUBLISHED content is never hard-deleted.

Revisit if: visibility checks become a hot path. Then cache the result in Redis and invalidate it whenever a status changes.