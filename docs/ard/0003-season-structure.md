# 0004. Season structure

- Status: Accepted
- Date: 2026-11-16

## Context

Every show is stored as series -> seasons -> episodes. But miniseries have no seasons and some shows have specials outside the main numbering.

## Options considered

- Episodes attach directly to the series when there's no season. Honest to the data but episodes have two possible kinds of parent, so every query must handle both paths and the database must enforce "exactly one parent."

- Every series always has at least one season. Every episode has exactly one parent, at the cost of a synthetic season for miniseries.

## Decision

We are choosing option 2. Every series has at least one season. A miniseries gets a single Season 1 and specials go in Season 0. Season numbers are unique within a series, enforced by UNIQUE (series_id, season_number).

## Consequences

Positive:
- Every episode has exactly one parent and queries stay uniform: ordering is always by season number, then episode number.

Negative:
- Miniseries store a season that doesn't exist in the real show.
- Clients must follow two conventions (below).

Obligations:
- The database cannot enforce "a series has at least one season," because foreign keys only point from child to parent. The series and its Season 1 are created in the same transaction.

Client conventions:
- Hide the season picker when a series has only one season so a presentation concern doesn't shape storage.
- Display Season 0 as "Specials," typically after the regular seasons.