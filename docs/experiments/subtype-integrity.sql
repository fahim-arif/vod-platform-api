-- Subtype integrity experiment
--
-- Question: with Option C (title + movie_details / series_details),
-- what does the database actually enforce with plain foreign keys,
-- and what does a composite foreign key on (id, kind) add?
--
-- Run from the project folder:
-- docker compose exec -T postgres psql -U <user> -d <database> < docs/experiments/subtype-integrity.sql
--
-- Some statements are meant to fail. psql keeps going after an error,
-- so compare each error in the output with the "Expect" comment above it.


-- Part 1: Setup (plain single-column foreign keys)

DROP SCHEMA IF EXISTS experiment CASCADE;
CREATE SCHEMA experiment;
SET search_path TO experiment;

CREATE TABLE title (
  id   BIGINT PRIMARY KEY,
  name TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('movie', 'series'))
);

CREATE TABLE movie_details (
  title_id        BIGINT PRIMARY KEY REFERENCES title(id),
  runtime_minutes INTEGER NOT NULL
);

CREATE TABLE series_details (
  title_id BIGINT PRIMARY KEY REFERENCES title(id),
  status   TEXT NOT NULL CHECK (status IN ('ongoing', 'ended'))
);

CREATE TABLE season (
  id            BIGINT PRIMARY KEY,
  series_id     BIGINT NOT NULL REFERENCES series_details(title_id),
  season_number INTEGER NOT NULL,
  UNIQUE (series_id, season_number)
);

INSERT INTO title (id, name, kind) VALUES (1, 'Inception', 'movie'), (2, 'Breaking Bad', 'series');
INSERT INTO movie_details (title_id, runtime_minutes) VALUES (1, 148);
INSERT INTO series_details (title_id, status) VALUES (2, 'ended');


-- Part 2: Tests with plain foreign keys

-- T1: Season 1 for Breaking Bad.
-- Expect: accepted.
INSERT INTO season (id, series_id, season_number) VALUES (1, 2, 1);

-- T2: A second Season 1 for Breaking Bad.
-- Expect: rejected by season_series_id_season_number_key (the unique pair).
INSERT INTO season (id, series_id, season_number) VALUES (2, 2, 1);

-- T3: A season for Inception, a movie.
-- Expect: rejected by season_series_id_fkey (no series_details row for title 1).
INSERT INTO season (id, series_id, season_number) VALUES (3, 1, 1);

-- T4: A series_details row for Inception.
-- Expect: ACCEPTED. The foreign key only checks that title 1 exists, not its kind.
INSERT INTO series_details (title_id, status) VALUES (1, 'ended');

-- T5: T3 again, now that T4 succeeded.
-- Expect: ACCEPTED. Inception now has a season; the season protection is bypassed.
INSERT INTO season (id, series_id, season_number) VALUES (3, 1, 1);

-- T6: A movie_details row for Breaking Bad, a series.
-- Expect: ACCEPTED, for the same reason as T4.
INSERT INTO movie_details (title_id, runtime_minutes) VALUES (2, 100);

-- T7: A movie with no movie_details row at all.
-- Expect: accepted. Nothing requires a title to have a detail row.
INSERT INTO title (id, name, kind) VALUES (3, 'Dune', 'movie');


-- Part 3: The fix (composite foreign keys on (title_id, kind))

-- Remove the invalid rows first: new constraints are checked against existing data.
DELETE FROM season WHERE series_id = 1;
DELETE FROM series_details WHERE title_id = 1;
DELETE FROM movie_details WHERE title_id = 2;

-- Make the (id, kind) pair referenceable. Adds no new restriction, since id is already unique.
ALTER TABLE title ADD CONSTRAINT title_id_kind_key UNIQUE (id, kind);

-- series_details: every row is labelled 'series', and that label must match the title's real kind.
ALTER TABLE series_details ADD COLUMN kind TEXT NOT NULL DEFAULT 'series' CHECK (kind = 'series');
ALTER TABLE series_details DROP CONSTRAINT series_details_title_id_fkey;
ALTER TABLE series_details ADD CONSTRAINT series_details_title_kind_fkey
  FOREIGN KEY (title_id, kind) REFERENCES title(id, kind);

-- movie_details: the mirror image, locked to 'movie'.
ALTER TABLE movie_details ADD COLUMN kind TEXT NOT NULL DEFAULT 'movie' CHECK (kind = 'movie');
ALTER TABLE movie_details DROP CONSTRAINT movie_details_title_id_fkey;
ALTER TABLE movie_details ADD CONSTRAINT movie_details_title_kind_fkey
  FOREIGN KEY (title_id, kind) REFERENCES title(id, kind);


-- Part 4: Tests after the fix

-- F1: T4 again, a series_details row for Inception.
-- Expect: rejected by series_details_title_kind_fkey. No title (1, 'series') exists.
INSERT INTO series_details (title_id, status) VALUES (1, 'ended');

-- F2: Sneaking it in by labelling it 'movie'.
-- Expect: rejected by series_details_kind_check. This table only allows 'series'.
INSERT INTO series_details (title_id, kind, status) VALUES (1, 'movie', 'ended');

-- F3: T5 again, a season for Inception.
-- Expect: rejected by season_series_id_fkey. Inception can no longer get into series_details.
INSERT INTO season (id, series_id, season_number) VALUES (3, 1, 1);

-- F4: T6 again, a movie_details row for Breaking Bad.
-- Expect: rejected by movie_details_title_kind_fkey. No title (2, 'movie') exists.
INSERT INTO movie_details (title_id, runtime_minutes) VALUES (2, 100);

-- F5: Changing Inception's kind to 'series' while its movie_details row exists.
-- Expect: rejected by movie_details_title_kind_fkey. The movie row would point at a (1, 'movie') that no longer exists.
UPDATE title SET kind = 'series' WHERE id = 1;

-- F6: A movie with no movie_details row, still.
-- Expect: accepted. The composite key does not fix this; detail rows must be
-- created in the same transaction as the title, in application code.
INSERT INTO title (id, name, kind) VALUES (4, 'Arrival', 'movie');

