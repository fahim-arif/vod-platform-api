# 0002. Catalog structure: class-table inheritance

- Status: Accepted
- Date: 2026-11-14

## Context
Movies and series share most fields (name, synopsis, artwork, genres, cast) but each has fields only it uses (runtime for movies: ongoing/ended status for series).

Many other things need to point at "a title" in general: genres, cast, search, watchlists.

Seasons must only ever belong to series.

My priority is that the database itself should prevent invalid shapes wherever practical.

## Options considered
A: Single table with kind (single-table inheritance). Everything in one place but type-specific fields must be nullable and seasons could attach to movies.

B: Separate Movie and Series tables (concrete-table inheritance). Strong integrity but shared fields are duplicated and everything that points at "a title" needs two foreign keys. There is also no single title identity, so cross-type queries like search need a UNION.

C: Shared Title plus detail tables (class-table inheritance). Shared things in one place, type-specific fields enforceable and seasons point at SeriesDetails.

## Decision
We are choosing option C with composite foreign keys. It keeps shared relations in one table while letting the database enforce the shapes. Seasons reference series_details and detail tables reference title by (id, kind). Title kind is stored as a Postgres enum, and each detail table's kind column is locked to its single value with a check constraint.

We rejected B because every relation to "a title" would need two foreign keys and a streaming catalog has many such relations.

## Consequences
The guarantees below were verified in [subtype-integrity.sql](../experiments/subtype-integrity.sql).

Positive:
- The database rejects a series row for a movie a season for a movie both detail rows for one title and changing a title's kind while its detail row exists.
- Relations to "a title" (genres, cast, watchlists) need only one foreign key.

Negative:
- More joins: reading a full title means joining its detail table.
- Two inserts per title.
- An extra kind column per detail table, plus a raw SQL step in a migration (the check constraint) that Prisma's schema doesn't express, so it has to be documented.
- Prisma types: both movieDetails and seriesDetails come back optional, so code must narrow by kind.
- Removing or renaming an enum value later is painful in Postgres.

Obligations:
- The database cannot stop a title from having no detail row. One service method creates a title and its detail row in a single transaction and it is the only way to create titles.
- Prisma results are mapped to a TypeScript discriminated union at the repository boundary.

Revisit if: the number of title kinds grows a lot (documentaries, specials, live events). Each new kind adds a detail table and an enum value.