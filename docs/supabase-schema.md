# PM Team Board — Supabase Schema

## Tables

### boards
The top-level entity. Each board gets a unique slug for shared access.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| name | text | NOT NULL | Board display name (editable) |
| slug | text | UNIQUE, NOT NULL | URL-safe identifier for shared link. Immutable after creation — changing it breaks all existing shared links. |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

### fields
Schema definitions for configurable fields on a board. Each row defines one field — its type, display order, and (for single-select) its options.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| board_id | uuid | FK → boards.id, NOT NULL | |
| name | text | NOT NULL | Display label (e.g., "Status", "Pod") |
| field_key | text | NOT NULL | Stable key used in projects.field_values JSONB (e.g., "status", "pod"). Immutable after creation — renaming the field updates `name` but not `field_key`. |
| field_type | text | NOT NULL | One of: text, single_select, date, person, url |
| options | jsonb | default '[]' | For single_select: ordered array of {value, label, color} |
| display_order | integer | NOT NULL, default 0 | Controls field ordering in table view and card detail |
| is_required | boolean | default false | |
| is_default | boolean | default false | Marks fields shipped with the board — prevents accidental deletion |
| created_at | timestamptz | default now() | |

**Unique constraint**: (board_id, field_key)

### team_members
People who can be assigned to projects via person-type fields.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| board_id | uuid | FK → boards.id, NOT NULL | |
| name | text | NOT NULL | Display name |
| color | text | | Badge color for UI differentiation |
| created_at | timestamptz | default now() | |

### projects
The cards. Title is a first-class column; all configurable field values stored in JSONB.

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| board_id | uuid | FK → boards.id, NOT NULL | |
| title | text | NOT NULL | Project/card name — always visible, not in JSONB |
| field_values | jsonb | default '{}' | Keyed by field_key. E.g., {"status": "in_progress", "priority": "p1_high", "owner": "uuid-of-team-member", "pod": "kubernetes", "start_date": "2025-07-01", "target_completion": "2025-08-15", "description": "...", "project_url": "https://..."} |
| display_order | integer | default 0 | Controls card ordering within a column. New projects are assigned max(display_order) + 1 for their column group, appending to the bottom. |
| created_at | timestamptz | default now() | |
| updated_at | timestamptz | default now() | |

### comments
Timestamped comments on projects. Author is a team member name (no auth, so no user ID).

| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK, default gen_random_uuid() | |
| project_id | uuid | FK → projects.id, NOT NULL | |
| author_name | text | NOT NULL | Free text — user selects their name from team members list. Not a FK; comments from removed team members are preserved with the name as written. |
| body | text | NOT NULL | Comment content |
| created_at | timestamptz | default now() | |

## JSONB field_values — Convention

The `field_values` JSONB on each project follows these conventions by field type:

| Field Type | Stored Value | Example |
|---|---|---|
| text | string | "Migrate DNS records to new provider" |
| single_select | string (option value) | "in_progress" |
| date | ISO 8601 date string | "2025-07-15" |
| person | uuid (team_member.id) | "a1b2c3d4-..." |
| url | string (full URL) | "https://docs.google.com/..." |

### Option value key convention

For single-select options, the `value` key is derived from the label by lowercasing, replacing spaces and special characters with underscores, and stripping anything that isn't alphanumeric or underscore.

Examples: `"In Flight"` → `in_flight`, `"P1 - High"` → `p1_high`, `"Q&A Review"` → `qa_review`

This convention is used both for manually created options (in Settings) and for options auto-created during CSV import. This matches the existing seed data pattern.

## Default Seed Data

On board creation, the app seeds these fields:

| Field | Key | Type | Options / Notes |
|---|---|---|---|
| Status | status | single_select | Not Started, In Progress, In Review, Completed |
| Priority | priority | single_select | P1 - High, P2 - Medium, P3 - Low |
| Owner | owner | person | |
| Pod | pod | single_select | (empty — user configures) |
| Start Date | start_date | date | |
| Target Completion | target_completion | date | |
| Description | description | text | |

## Indexes

- `projects.board_id` — every board load queries by board
- `comments.project_id` — card detail loads comments
- `fields.board_id` — schema loaded with board
- `boards.slug` — unique, used for shared link lookup

## Row-Level Security

v1 uses permissive RLS policies (`using (true)` / `with check (true)`) on all tables. Anyone with the Supabase anon key has full read/write access to all data. The non-guessable board slug is the only access control in v1 — there is no board_id scoping at the RLS layer.

This is the correct posture for a small-team trust model where the anon key is embedded in the deployed app. v2 would tighten this significantly with individual auth and board-membership-scoped policies.

## Notes

- **Why field_key is immutable**: If a user renames "Pod" to "Squad," the display label changes but the JSONB key stays `pod`. This avoids having to rewrite every project's field_values when a field is renamed.
- **Why slug is immutable**: Changing a board's slug breaks all existing shared links. Board display name is editable; slug is set at creation and never changes. Mirrors field_key immutability rationale.
- **Why person stores a UUID, not a name**: Referencing team_member.id means renaming a person doesn't orphan their assignments.
- **Why author_name on comments is free text**: No auth means no user identity. The UI prompts "who are you?" from the team members list, but it's not enforced. Acceptable for a small trust-based team. Removed team members' comments are preserved with the name as written.
