```
┌─────────────────────────────────────────────┐
│              pm-team-board                  │
│                                             │
│   v0.1.0  •  Apr 2026                       │
│   MIT License                               │
└─────────────────────────────────────────────┘
```

## The Problem

Small PM teams need a shared visual board to track who's working on what. The options are a lose-lose: free tiers of Notion and Trello lock core features behind paywalls, while Jira and Asana are overbuilt for a team that just needs to see project status across 2-8 people. The result is teams either pay for features they barely use or fall back to spreadsheets that lack the workflow a kanban board provides.

## What This Is

A configurable, web-based kanban board built for small PM teams. It ships with sensible defaults — status, priority, ownership, pod — but lets teams define their own fields, options, and views. No accounts, no paywall, no enterprise overhead.

**The board is accessible to the whole team via a shared link.**

## Key Features

- **Configurable schema** — Add, rename, or remove fields. Supported types: text, single-select, date, person, URL. Ships with Status, Priority, Owner, Pod, Start Date, Target Completion, and Description pre-configured.
- **Multiple kanban views** — Group cards by any categorical field: status, owner, priority, pod, or any field you create. Adding a new field automatically creates a new view — no code changes required.
- **Table view** — Flat list with sortable and filterable columns for bulk scanning.
- **Drag-and-drop** — Move cards between columns to update the grouped field. Drag to "In Review" and the status updates.
- **Card detail and comments** — Click any card to edit fields inline and add timestamped comments.
- **Settings panel** — Manage fields, options, and team members from a slide-out panel without leaving the board.
- **CSV import and export** — Export the board as CSV. Import from Notion, Sheets, or any CSV with a column-mapping step.

## Status

Active development. Planning complete; build in progress.

See [`docs/build-sequence.md`](docs/build-sequence.md) for the full build plan.

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Frontend | React + Vite | Fast iteration, consistent with portfolio stack |
| Styling | Tailwind CSS + shadcn/ui | Radix primitives + Tailwind; covers modal, sheet, select, date picker out of the box |
| Database | Supabase (free tier) | Postgres-backed, pairs well with Vercel, built-in realtime for v2 |
| Deployment | Vercel | Consistent with portfolio stack |
| Drag-and-drop | dnd-kit | Actively maintained, accessible, React 18 compatible |
| CSV | Papaparse | Client-side parsing, no server needed |

## Architecture Decisions

The full set of decisions is documented in [`docs/component-architecture.md`](docs/component-architecture.md) and the PRD ([`docs/pm-team-board-prd.md`](docs/pm-team-board-prd.md)). A few that shaped the design:

- **Data-driven views** — KanbanView receives a field definition as a prop and derives columns from the field's data. Add a new team member or option in Settings and a new column appears automatically — no code changes.
- **JSONB field_values** — Configurable field values are stored as JSONB on the projects table, keyed by immutable field_key. Renaming a field updates the display label but never touches the data.
- **Single board per deployment** — v1 scopes to one board per deployed instance. A new team forks the repo, runs the migration, and deploys. Self-serve board creation is a prioritized backlog item.
- **Shared link access** — No individual auth in v1. The non-guessable slug is the access control. Appropriate for a small, known team.

## Running Locally

> Requires a Supabase project. See [Prerequisites](#prerequisites) below.

```bash
git clone https://github.com/stlevy53/pm-team-board.git
cd pm-team-board
npm install
cp .env.example .env.local
# Add your Supabase URL and anon key to .env.local
npm run dev
```

Navigate to `http://localhost:5173/board/product-project-board`.

## Prerequisites

1. Create a project at [supabase.com](https://supabase.com)
2. Run [`supabase/migrations/001_initial_schema.sql`](supabase/migrations/001_initial_schema.sql) in the Supabase SQL Editor
3. Copy your project URL and anon key into `.env.local`

## Deploying to Vercel

```bash
vercel
```

Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` in your Vercel project settings. The `vercel.json` in this repo handles SPA routing — no additional config needed.

## Schema Migrations

Migration files live in `supabase/migrations/` and are numbered sequentially. To apply a migration, run the file in the Supabase SQL Editor. To rebuild the database from scratch, run the files in order.

## Documentation

| File | Contents |
|---|---|
| [`docs/pm-team-board-brief.md`](docs/pm-team-board-brief.md) | Problem, solution, scope, architecture decisions |
| [`docs/pm-team-board-prd.md`](docs/pm-team-board-prd.md) | Full product requirements, acceptance criteria, resolved decisions |
| [`docs/component-architecture.md`](docs/component-architecture.md) | Project structure, data flow, component responsibilities |
| [`docs/supabase-schema.md`](docs/supabase-schema.md) | Table definitions, JSONB conventions, RLS notes |
| [`docs/build-sequence.md`](docs/build-sequence.md) | 12-phase build plan with testable outputs per phase |
| [`docs/backlog.md`](docs/backlog.md) | Post-v1 features, prioritized |

## License

[MIT](LICENSE)
