# vod-platform-api

A video-on-demand (VOD) streaming backend: content catalog, regional licensing windows, and an asynchronous video processing pipeline.

> **Status:** In active development. Current focus: catalog data model (titles, seasons, episodes, playable assets).

## Tech stack

- **NestJS** (TypeScript) for the API
- **PostgreSQL** with **Prisma** ORM
- **Redis** for caching and job queues
- **BullMQ** for background jobs
- **Docker Compose** for local infrastructure

## Planned scope

- **Catalog:** movies and series, with seasons and episodes
- **Availability:** licensing windows per region, supporting re-licensing over time
- **Assets:** multiple assets per playable item (main content, trailers), processed through a BullMQ pipeline
- **Publishing:** unpublish instead of hard delete, so user data like watch history survives

## Design decisions

Architecture decisions are recorded as ADRs in [`docs/adr/`](docs/adr/), each covering the context, options considered, and tradeoffs.

## Running locally

**Prerequisites:** Node.js, pnpm, Docker

1. Start Postgres and Redis:

   ```bash
   docker compose up -d
   ```

2. Install dependencies:

   ```bash
   pnpm install
   ```

3. Create a `.env` file with your database and Redis connection settings (`DATABASE_URL` for Prisma).

4. Apply database migrations:

   ```bash
   pnpm prisma migrate dev
   ```

5. Start the API in watch mode:

   ```bash
   pnpm run start:dev
   ```

To browse the database, run `pnpm prisma studio`.

## Tests

```bash
# unit tests
pnpm run test

# e2e tests
pnpm run test:e2e

# test coverage
pnpm run test:cov
```