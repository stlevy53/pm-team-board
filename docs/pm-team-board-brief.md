# PM Team Board

## Problem

Product management teams need a lightweight way to track and communicate backlog, active, and completed work across their team. Existing tools either lock core functionality behind paywalls (Notion's row limits, Trello's advanced views) or are overbuilt for a small PM team's needs (Jira, Asana). The result: teams either pay for features they barely use or cobble together spreadsheets and docs that lack the visual workflow a kanban board provides.

## Target User

PM leaders managing a small team (2-8 PMs) who need a shared, visual project board without enterprise tooling overhead. Comfortable with web apps but not looking to self-host or configure complex infrastructure.

## Proposed Solution

A configurable, web-based kanban board purpose-built for PM team workflows. Users define their own fields, team members, and groupings — then view work across multiple dimensions (status, owner, priority, pod/team). Data persists in Supabase and is accessible to the team via a shared link.

## Key Features

- **Configurable schema**: Add, rename, or remove fields per board. Supported field types: text, single-select, date, person, URL. Ships with sensible defaults: Status (Not Started, In Progress, In Review, Completed), Priority (P1-High, P2-Medium, P3-Low), plus Project, Owner, Pod, Start Date, Target Completion, and Description fields pre-configured.
- **Multiple kanban views**: Group cards by any categorical field — status, owner, priority, pod. Switch views without losing context.
- **Table view**: Flat list with sortable and filterable columns for bulk scanning.
- **Drag-and-drop**: Move cards between columns to update the grouped field (e.g., drag from "In Progress" to "In Review" updates status).
- **Card detail & comments**: Click to expand full project details, edit fields inline, and add timestamped comments visible to the team.
- **Team management**: Add/remove team members. Assign owners to projects.
- **CSV import/export**: Export the board as CSV. Import via CSV with a field-mapping step to match columns to board fields.
- **Settings panel**: Lightweight slide-out panel for managing fields, single-select options, and team members. Keeps the board UI focused on work.
- **Shared access**: Team accesses the board via a shared link. No individual auth required.

## Architecture Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Data layer | Supabase (free tier) | Postgres-backed, pairs well with Vercel, generous free tier, built-in realtime capability if needed later |
| Auth model | Shared link (no individual login) | Reduces scope for v1; team trust model is sufficient for small groups |
| Real-time sync | Refresh on load | Acceptable for v1; Supabase realtime subscriptions available as a low-effort upgrade path |
| Field types | Text, single-select, date, person, URL | Covers core PM workflow fields without overbuilding |
| Defaults | Pre-configured fields and statuses | Reduces cold-start friction; all defaults remain editable |
| Platform | Desktop-first | Kanban on mobile is a poor experience; team primarily works from desktops |
| Deployment | Vercel | Consistent with portfolio stack |
| Frontend | React | Consistent with portfolio stack |
| Board model | Single board per deployment | v1 scopes to one board per deployed instance; self-serve board creation is a backlog item |

## Scope

**v1:**
- Pre-configured default fields and statuses (all editable)
- Configurable fields (text, single-select, date, person, URL) and team members
- Settings panel for field and team management
- Kanban views grouped by status, owner, priority, pod
- Table view with sort and filter
- Drag-and-drop card movement
- Card detail/edit modal with comment threads (including comment delete)
- Supabase persistence (free tier)
- Shared access via link
- CSV import and export with field mapping
- Desktop-first layout

**v2 (if warranted):**
- Self-serve board creation (no SQL required)
- Supabase realtime subscriptions for live sync
- Individual auth and activity log
- Additional field types (multi-select, number)
- Responsive/mobile layout
