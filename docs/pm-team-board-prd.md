**PM Team Board**

Product Requirements Document

**Status:** Draft

**Owner:** Stephen Levy

**Updated:** April 2026

| Field | Value |
| --- | --- |
| Document Title | PM Team Board PRD |
| Author | Stephen Levy |
| Status | Draft |
| Created | April 2026 |
| Last Updated | April 2026 |
| Predecessor | [PM Team Board Brief](pm-team-board-brief.md) |

| Version | Date | Author | Notes |
| --- | --- | --- | --- |
| 0.1 | April 2026 | Stephen Levy | Initial draft |
| 0.2 | April 2026 | Stephen Levy | Resolved contradictions and gaps from planning review |

# **1. Executive Summary**

## **1.1 Product Vision**

PM Team Board is a configurable, web-based kanban board for small PM teams to track and communicate backlog, active, and completed work. It ships with sensible defaults for common PM workflows — status, priority, ownership, pod — but lets teams define their own fields, options, and views. Data persists in Supabase and the board is accessible to the team via a shared link. No accounts, no paywall, no enterprise overhead.

## **1.2 Problem Statement**

Small PM teams (2-8 people) need a shared visual board to manage project work. The existing options create a lose-lose: free tiers of tools like Notion and Trello lock core functionality behind paywalls (Notion's row limits, Trello's advanced views and power-ups), while enterprise tools like Jira and Asana are overbuilt for a team that just needs to see who's working on what. The result is teams either pay for features they barely use or fall back to spreadsheets and docs that lack the visual workflow a kanban board provides.

# **2. Scope**

## **2.1 In-Scope**

- Configurable board schema: add, rename, reorder, and remove fields (text, single-select, date, person, URL types)
- Pre-configured default fields and statuses that work out of the box, all editable
- Kanban views grouped by any single-select or person field (ships with status, owner, priority, pod views)
- Table view with sortable and filterable columns (filtering is client-side)
- Drag-and-drop card movement between columns, updating the grouped field value
- Card detail modal with inline field editing and timestamped comment threads
- Comment delete (comments are not editable in v1)
- Team member management (add, edit, remove)
- Settings panel for field, option, and team configuration
- CSV import with column-to-field mapping and CSV export
- Supabase persistence (free tier) with shared-link access model
- Desktop-first layout

## **2.2 Non-Goals**

- **Individual authentication or user accounts.** Adds significant scope; the shared-link trust model is sufficient for small teams in v1.
- **Real-time collaborative sync.** Refresh-on-load is acceptable for v1. Supabase realtime subscriptions are a low-effort upgrade path for v2.
- **Mobile-responsive layout.** Kanban boards on mobile are a poor experience. The target user works from a desktop.
- **Multi-board management / self-serve board creation.** v1 is single-board-per-deployment. The board is created via SQL seed; a new team forks the repo and runs the migration. Self-serve board creation (no SQL required) is a prioritized backlog item for v2.
- **Notifications or email digests.** No auth means no notification targets. Deferred to v2 with individual accounts.
- **Audit trail or activity log.** Requires individual auth to be meaningful. Deferred.
- **Comment editing.** Comments are immutable once posted in v1. Delete is supported. Comment editing is a backlog item.

# **3. Actors & User Personas**

## **3.1 PM Lead (Board Admin)**

**Who they are:** The PM leader who creates and configures the board for their team. Defines the schema, manages team members, and sets up the workflow. Also uses the board daily as a practitioner.

**Jobs to be done:**

1. When I'm setting up a new board for my team, I want to configure fields and statuses that match our workflow, so I can have a board that's ready to use without forcing my team into a generic template. (P0)

   *Acceptance criteria:*
   1. User can add, rename, reorder, and delete fields from the settings panel
   2. User can add, rename, recolor, reorder, and delete options on any single-select field
   3. Default fields and statuses are pre-configured on board creation
   4. All default fields are editable and deletable

2. When I need to see my team's workload at a glance, I want to view the board grouped by owner, so I can identify who's overloaded and who has capacity. (P0)

   *Acceptance criteria:*
   1. Owner view displays one column per team member with their assigned projects
   2. Each card shows status and priority badges for quick scanning
   3. Column headers display project count

3. When a team member joins or leaves, I want to add or remove them from the board, so I can keep ownership assignments current. (P0)

   *Acceptance criteria:*
   1. User can add a team member with name and badge color from settings
   2. User can remove a team member; projects assigned to that person show as unassigned
   3. Person-type field dropdowns reflect the current team member list immediately
   4. Removing a team member does not delete their existing comments; comments are preserved with the author name as written at time of posting

4. When I want to migrate existing project data from Notion or a spreadsheet, I want to import a CSV and map columns to board fields, so I can avoid re-entering 30+ projects manually. (P1)

   *Acceptance criteria:*
   1. User can upload a CSV file and preview parsed rows
   2. Field mapper displays CSV columns alongside board fields for manual mapping
   3. Unmapped columns are ignored; mapped columns populate field_values on created projects
   4. Import creates projects in batch with a success/error summary

## **3.2 PM Team Member (Contributor)**

**Who they are:** An individual contributor PM who uses the board daily to track their own work, update project status, and communicate progress. Accesses the board via a shared link.

**Jobs to be done:**

1. When I finish a phase of work on a project, I want to drag my card to the next status column, so I can communicate progress to my team without a standup or status email. (P0)

   *Acceptance criteria:*
   1. User can drag a card from one column to another in any kanban view
   2. The grouped field value updates to match the target column (e.g., status changes from "In Progress" to "In Review")
   3. Card position within the target column is preserved where dropped
   4. Change persists to Supabase immediately

2. When I need to add context to a project, I want to add a comment on the card, so I can keep project-level discussion visible to my team. (P0)

   *Acceptance criteria:*
   1. User can add a timestamped comment from the card detail modal
   2. User selects their name from the team members list before posting
   3. Comments display in chronological order with author name and timestamp
   4. Comment count badge displays on the card in kanban and table views

3. When I'm looking for a specific project, I want to scan or filter the table view, so I can find it without scrolling through the kanban columns. (P0)

   *Acceptance criteria:*
   1. Table view displays all projects with all fields as columns
   2. Columns are sortable (ascending/descending) by clicking the header
   3. Table view includes a filter bar for filtering by any single-select or person field
   4. Clicking a row opens the card detail modal

# **4. Functional Requirements**

## **4.1 Requirements Summary**

| Priority | Requirement | Acceptance Criteria |
| --- | --- | --- |
| P0 | Board loads by slug from shared link | Board data, fields, team members, and projects load from Supabase on navigation to /board/:slug |
| P0 | Kanban view grouped by any categorical field | KanbanView renders columns from field options (single-select) or team members (person). Ships with status, owner, priority, pod views |
| P0 | Table view with sort and filter | All projects displayed in flat table; columns sortable by header click; filter bar for per-field filtering (client-side) |
| P0 | Drag-and-drop between kanban columns | Card moves between columns; grouped field value and display_order update in Supabase |
| P0 | Card detail modal with inline editing | All field values editable inline; changes persist immediately |
| P0 | Comment threads on cards | Add timestamped comments with author name; display chronologically; delete with confirmation |
| P0 | Create, edit, delete projects | New project creates with title + default field values; all fields editable; delete with confirmation |
| P0 | Team member management | Add/edit/remove team members from settings panel; person fields reflect changes |
| P0 | Field management | Add/rename/reorder/delete fields from settings panel; field_key immutable after creation |
| P0 | Single-select option management | Add/rename/recolor/reorder/delete options on any single-select field |
| P0 | Default seed data | New board created with pre-configured Status, Priority, Owner, Pod, Start Date, Target Completion, Description fields |
| P1 | CSV export | Export all projects as CSV with field names as column headers |
| P1 | CSV import with field mapping | Upload CSV, preview rows, map columns to board fields, batch-create projects |
| P1 | View tabs derived from schema | ViewTabs displays a kanban option for every single-select and person field automatically; data-driven from initial build |

## **4.2 Board & Views**

### **Board Loading**

The board loads from Supabase when a user navigates to `/board/:slug`. The load sequence fetches the board record first (to obtain `board.id`), then fetches field definitions and team members in parallel. Projects are fetched in parallel with the fields/team members step. The board renders once all data is in memory.

`/` redirects to `/board/product-project-board`. v1 is single-board-per-deployment; board creation via the UI is a backlog item.

*Acceptance criteria:*
1. Navigating to `/board/:slug` loads and displays the board
2. Invalid slug shows an error state, not a blank page
3. Board name displays in the header

### **Kanban Views**

KanbanView is a single, data-driven component. It receives a field definition as a prop and derives its columns from the field's data: options array for single-select fields, team members list for person fields. The component has no knowledge of specific fields — it groups cards by whatever field it's given.

*Acceptance criteria:*
1. Status view groups projects by status field options (Not Started, In Progress, In Review, Completed)
2. Owner view groups projects by team member
3. Priority view groups projects by priority field options
4. Pod view groups projects by pod field options
5. Each column header displays the option/person label and a project count
6. Projects with no value for the grouped field appear in an "Unassigned" / "No [Field]" column
7. Adding a new option or team member in settings creates a new column in the relevant view without code changes

### **Table View**

Flat table displaying all projects with field values as columns. Column order follows field display_order.

*Acceptance criteria:*
1. All fields display as columns in display_order sequence
2. Columns sortable by clicking header (toggle ascending/descending)
3. Clicking a row opens the card detail modal
4. Person fields display the team member name, not the UUID
5. Single-select fields display the option label with color badge

### **Table Filter**

Filter bar above the table for narrowing projects by field values. Filtering is client-side — all projects are already in memory, no Supabase query required.

*Acceptance criteria:*
1. Filter bar allows filtering by any single-select or person field
2. Multiple filters can be active simultaneously (AND logic — projects must match all active filters)
3. Each active filter displays as a removable badge
4. Filter state is local — cleared on page refresh, not persisted to Supabase
5. "Clear all" removes all active filters
6. Filtered row count displays alongside the filter bar (e.g., "12 of 34 projects")

### **View Tabs**

Tab bar for switching between table and kanban views. Data-driven from the board's field schema — every single-select or person field is automatically a valid kanban grouping. Ships with default tabs (All Projects, Status, Owner, Priority, Pod) but new fields added in Settings create new tabs automatically without code changes.

*Acceptance criteria:*
1. Default tabs render on board load
2. Active tab is visually distinguished
3. Switching tabs preserves no stale state from the previous view
4. Any new single-select or person field created in Settings automatically becomes available as a kanban view tab

## **4.3 Card Management**

### **Card Creation**

Users create a new project from any view. Minimum required input is a title.

*Acceptance criteria:*
1. "New" button is accessible from any view
2. New project is created with the provided title and empty field_values
3. If created from a kanban view, the grouped field is pre-populated with the column's value (e.g., creating from the "In Progress" column sets status to "in_progress")
4. If created from the table view, no fields are pre-populated beyond the title
5. New card is appended to the bottom of its column (display_order = max display_order in that column + 1)
6. New card appears in the correct position without requiring a page refresh

### **Card Detail Modal**

Full project detail view. Displays all fields with their current values. Fields are editable inline — click a value to switch to edit mode.

*Acceptance criteria:*
1. Modal opens when clicking a card (kanban) or row (table)
2. All fields render with appropriate display components (text, badge, date, linked name, clickable URL)
3. Clicking a field value toggles to the appropriate editor (text input, select dropdown, date picker, person picker, URL input)
4. Edits persist to Supabase on blur or confirmation, not on every keystroke
5. Modal includes a delete button with a confirmation dialog
6. Comment thread displays below the fields

### **Comment Threads**

Timestamped comments on each project card.

*Acceptance criteria:*
1. Comments display in chronological order with author name and relative timestamp
2. User selects their name from the team members dropdown before posting
3. Comment body supports plain text (no markdown or rich text in v1)
4. Empty comments cannot be submitted
5. Comments are not editable after posting (immutable in v1)
6. User can delete a comment with a confirmation dialog
7. Card displays a comment count badge in kanban and table views
8. Removing a team member does not delete their comments; comments are preserved with the author name as written

## **4.4 Drag-and-Drop**

### **Cross-Column Movement**

Dragging a card between columns updates the grouped field's value.

*Acceptance criteria:*
1. Card is visually lifted on drag start with a drop indicator in target columns
2. Dropping in a different column updates the project's field_values for the grouped field
3. Dropping in the same column reorders without changing the field value
4. display_order updates for all affected cards in the target column
5. Changes persist in a single Supabase call

## **4.5 Settings & Configuration**

### **Settings Panel**

Slide-out panel from the right side of the board. Contains three management sections: Fields, Options, Team.

*Acceptance criteria:*
1. Settings panel opens/closes without navigating away from the board
2. Changes in settings reflect immediately in the board view when the panel closes
3. Panel sections are collapsible or tabbed for scannability

### **Field Management**

*Acceptance criteria:*
1. User can add a new field with name, type, and display order
2. User can rename a field display name (field_key remains immutable after creation)
3. User can rename the board display name (slug remains immutable after creation — changing it would break all existing shared links)
4. User can reorder fields (affects table column order and card detail field order)
5. User can delete a non-default field with confirmation
6. Default fields can be deleted but show a warning that this is irreversible
7. Deleting a field does not retroactively remove that key from existing projects' field_values (orphaned data is acceptable)

### **Option Management (Single-Select Fields)**

*Acceptance criteria:*
1. User can add a new option with label and color to any single-select field; value key is auto-derived from label using slugify convention (lowercase, underscores, strip non-alphanumeric)
2. User can rename an option label (value key remains stable)
3. User can change an option's color
4. User can reorder options (affects kanban column order)
5. User can delete an option with confirmation; projects with that value show as "Unknown" or empty

### **Team Management**

*Acceptance criteria:*
1. User can add a team member with name and badge color
2. User can edit a team member's name or color
3. User can remove a team member with confirmation
4. Removing a team member sets their assigned projects' person field to null (unassigned)
5. Removing a team member does not delete their comments; existing comments are preserved with the author name as written at time of posting

## **4.6 CSV Import & Export**

### **CSV Export**

*Acceptance criteria:*
1. Export button generates a CSV with one row per project
2. Column headers use field display names (not field_keys)
3. Person fields export as the team member's name
4. Single-select fields export as the option label
5. File downloads immediately to the user's browser

### **CSV Import**

*Acceptance criteria:*
1. User uploads a CSV file; app parses headers and displays a preview of the first 5 rows
2. Field mapper shows CSV columns on the left, board fields on the right as dropdowns
3. User maps each CSV column to a board field or marks it as "skip"
4. For single-select fields, imported values are matched against existing options (case-insensitive); unmatched values are auto-created as new options using the slugify convention for the value key (e.g., "In Flight" → `in_flight`) and assigned a default gray color
5. For person fields, imported names are matched against existing team members (case-insensitive); unmatched names are not created automatically — they are listed in the post-import summary so the user can manually assign those projects afterward
6. Submit creates projects in batch; summary shows count created, any errors, and a list of projects with unmatched person values for manual follow-up
7. Import does not overwrite existing projects — it only creates new ones

# **5. User Experience Requirements**

## **5.1 Design Principles**

1. **Board-first.** The kanban board is the primary interface. Every other view and panel is secondary to the board's readability and usability.
2. **Zero-config start.** A new user sees a functional, pre-configured board immediately. Configuration is available but never required to get started.
3. **Minimal chrome.** The UI prioritizes the work content — cards, columns, data — over toolbars, menus, and settings. Admin surfaces stay hidden until invoked.
4. **Direct manipulation.** Drag to change status. Click to edit. Changes happen where the data lives, not in a separate form.
5. **Data-driven views.** Views and columns derive from the board's schema, not from hardcoded UI. Adding a field or option extends the interface automatically.

## **5.2 Key User Flows**

### **Flow 1: First Board Load (New User)**

1. User navigates to `/board/product-project-board` via shared link
2. Board loads with default fields pre-configured (Status, Priority, Owner, Pod, Start Date, Target Completion, Description)
3. Board displays an empty state with a prompt to add team members and create the first project
4. User opens Settings → Team, adds team members
5. User clicks "New," enters a project title, and the first card appears

### **Flow 2: Daily Status Update (Team Member)**

1. User opens the board via bookmarked shared link
2. Default view is the status kanban (Status tab)
3. User finds their card in "In Progress," drags it to "In Review"
4. Status field updates; card appears in the new column
5. User clicks the card, adds a comment: "Ready for Stephen to review — deck is in the shared drive"
6. User closes the modal, sees the comment count badge on the card

### **Flow 3: Workload Review (PM Lead)**

1. User switches to Owner View tab
2. Columns display one per team member with project counts
3. User scans for imbalances — notices one PM has 12 cards, another has 4
4. User drags a card from the overloaded column to another PM's column; owner field updates
5. User switches to Priority View to check that P1 items are distributed appropriately

### **Flow 4: Adding a New Field**

1. User opens Settings → Fields
2. Clicks "Add Field," enters name "Quarter," selects type "Single-Select"
3. Adds options: Q1, Q2, Q3, Q4 with distinct colors
4. Saves; new field appears in table view as a column and in card detail as an editable field
5. ViewTabs now offers "Quarter" as a kanban grouping option automatically

### **Flow 5: CSV Import from Notion Export**

1. User exports their Notion board as CSV
2. Opens CSV Import from the board header
3. Uploads the file; preview shows the first 5 rows with Notion's column headers
4. Maps "Name" → Project title, "Product Manager" → Owner, "Pod" → Pod, "Status" → Status, "Priority" → Priority, etc.
5. Submits; projects are created in batch
6. Post-import summary shows projects created and any person fields that couldn't be matched to existing team members
7. User reviews the board — cards appear with mapped field values populated; manually assigns any unmatched owners

# **6. Non-Functional Requirements**

## **6.1 Performance**

| Action / Metric | Target |
| --- | --- |
| Board initial load (including Supabase queries) | < 2 seconds |
| View switch (tab change) | < 200ms (client-side, no network call) |
| Table filter (client-side) | < 100ms (array manipulation on in-memory data) |
| Card drag-and-drop persist | < 500ms round-trip to Supabase |
| CSV import (50 rows) | < 5 seconds |

## **6.2 Security & Access Control**

v1 uses Supabase's anon key with permissive RLS policies (`using (true)` on all tables). Anyone with the anon key has full read/write access to all boards in the database. The non-guessable board slug embedded in the shared link is the practical access control in v1.

v2 mitigation: individual auth with RLS policies scoped to board membership.

## **6.3 Scalability**

Designed for small teams (2-8 members, <200 projects per board). Supabase free tier supports up to 500MB of database storage, which is well beyond this use case. JSONB field_values queries are performant at this scale without indexing beyond board_id.

# **7. Integrations & Dependencies**

## **7.1 System Integrations**

### **Supabase**

Postgres database for all board data. Accessed via the Supabase JavaScript client library using the anon key. All queries are centralized in a single `database.js` module.

*Acceptance criteria:*
1. All CRUD operations use the Supabase client, not raw fetch calls
2. Board load sequence: fetchBoardBySlug → (fetchFields + fetchTeamMembers in parallel) → fetchProjects
3. Mutations return updated data or trigger a refetch of the affected table

### **Vercel**

Hosting and deployment for the React frontend. No server-side rendering required — the app is a static SPA with client-side Supabase queries.

*Acceptance criteria:*
1. App deploys via `vercel` CLI or GitHub integration
2. Environment variables (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`) are configured in Vercel project settings
3. Slug-based routing works with Vercel's SPA fallback configuration

## **7.2 Dependencies**

| Dependency | Owner | Impact if Delayed |
| --- | --- | --- |
| Supabase project creation | Stephen Levy | Cannot persist data; app is non-functional |
| Vercel project setup | Stephen Levy | Cannot deploy; development limited to localhost |
| dnd-kit library | Open source | Drag-and-drop blocked; could substitute with alternative |
| Papaparse library | Open source | CSV import/export blocked; low risk |

# **8. Success Metrics**

Since this is both a team tool and a portfolio project, success has two dimensions:

**As a team tool:**
- Board replaces the existing Notion project board within 2 weeks of deployment
- All team members (3 PMs) actively use the board for daily status tracking
- Zero return to Notion or spreadsheet workarounds after migration

**As a portfolio project:**
- Demonstrates full-stack capability: React frontend, Supabase backend, data modeling, configurable schema
- README clearly communicates the problem, solution, and technical decisions
- Deployed and functional at a public Vercel URL

# **9. Risks, Constraints & Assumptions**

| Type | Description | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- |
| Risk | Supabase free tier rate limits or storage caps hit during normal use | Low | High | Monitor usage; upgrade to Pro ($25/mo) if needed |
| Risk | Shared link is exposed beyond the team; unauthorized edits | Medium | Medium | Slug is non-guessable; v2 adds auth. Board data is not sensitive enough to warrant auth in v1 |
| Risk | JSONB queries become slow with large numbers of projects | Low | Low | Designed for <200 projects; add GIN indexes if needed |
| Risk | dnd-kit has breaking changes or becomes unmaintained | Low | Medium | Library is actively maintained; alternative (pragmatic-drag-and-drop) exists |
| Constraint | No individual auth in v1 | — | — | Limits ability to track who made changes; acceptable for trust-based team |
| Constraint | Supabase free tier (500MB storage, 50K monthly active users) | — | — | Well within limits for a 3-person team with <200 projects |
| Constraint | Desktop-first layout | — | — | Team works from desktops; mobile is a poor kanban experience |
| Constraint | Single board per deployment | — | — | v1 board created via SQL seed; self-serve creation is a backlog item |
| Assumption | Team of 2-8 PMs is the usage ceiling for v1 | — | — | If adopted by larger teams, auth and permissions become necessary |
| Assumption | Refresh-on-load is acceptable; team doesn't need real-time sync | — | — | If team members frequently overwrite each other's changes, add Supabase realtime in v2 |
| Assumption | CSV import from Notion export will map cleanly to board fields | — | — | Field mapper handles mismatches; unmatched single-select values create new options; unmatched person names flagged in summary |

# **10. Decisions & Open Questions**

## **10.1 Resolved Decisions**

| ID | Topic | Decision | Rationale |
| --- | --- | --- | --- |
| RD-01 | Data layer | Supabase (free tier) | Postgres-backed, pairs with Vercel, generous free tier, built-in realtime for v2 |
| RD-02 | Auth model | Shared link, no individual login | Reduces v1 scope; team trust model is sufficient for small groups |
| RD-03 | Real-time sync | Refresh on load | Acceptable for v1; Supabase realtime is a low-effort upgrade |
| RD-04 | Field value storage | JSONB on projects table | Cleaner than EAV for <200 projects; title pulled out as first-class column |
| RD-05 | field_key immutability | field_key never changes after creation | Prevents rewriting every project's field_values on field rename |
| RD-06 | Person field storage | UUID reference to team_members.id | Renaming a person doesn't orphan assignments |
| RD-07 | Comment author | Free text (selected from team list) | No auth = no user identity enforcement; honor system is acceptable |
| RD-08 | Default board seed | Pre-configured fields and statuses | Reduces cold-start friction; all defaults remain editable |
| RD-09 | Kanban architecture | Data-driven KanbanView component | One component handles all kanban views; columns derived from field data, not hardcoded |
| RD-10 | Platform | Desktop-first | Kanban on mobile is a poor experience; target users work from desktops |
| RD-11 | Field types at launch | Text, single-select, date, person, URL | Covers core PM workflow fields without overbuilding |
| RD-12 | Settings UI | Slide-out panel | Keeps board UI focused on work; admin surface is available but not persistent |
| RD-13 | CSV import/export | Included in v1 | Enables migration from Notion; export is near-trivial; import requires field mapper |
| RD-14 | ViewTabs scope | Auto-expose all single-select/person fields as kanban views | Keeps view system extensible without code changes as schema evolves; consistent with data-driven KanbanView architecture |
| RD-15 | "New" button context | Kanban view pre-populates the grouped field with the column's value; table view creates with title only | Reduces manual field-setting when adding a card directly to a specific column |
| RD-16 | Slug mutability | Board name editable; slug immutable after creation | Changing slug breaks all existing shared links; mirrors field_key immutability rationale (RD-05) |
| RD-17 | RLS posture | Permissive (using (true)) — no board_id scoping at RLS layer | Anon key + non-guessable slug is the v1 access model; board-scoped RLS requires individual auth (v2) |
| RD-18 | Board model | Single-board-per-deployment in v1 | Reduces scope; self-serve creation adds meaningful UI and DB complexity; fork-and-deploy model acceptable for portfolio project |
| RD-19 | Comment mutability | Comments immutable (no edit); delete supported | Edit adds inline UI complexity; delete is a single call and prevents user frustration from posting mistakes |
| RD-20 | Option value key convention | Slugify: lowercase, underscores, strip non-alphanumeric | Consistent with seed data pattern; deterministic and readable |
| RD-21 | CSV import: unmatched person names | Flagged in post-import summary; not auto-created | Auto-creating team members from CSV could pollute the team list with typos; user review is safer |
| RD-22 | New project display_order | Append to bottom (max + 1) | Cheaper than bulk-incrementing existing cards; matches natural expectation that new work lands at the bottom |
| RD-23 | Table filtering | Client-side only; not persisted | Projects already in memory; no Supabase query needed; filter state cleared on refresh is acceptable |
| RD-24 | UI component library | shadcn/ui | Radix UI primitives + Tailwind; copy-into-codebase model avoids runtime dependency lock-in; covers modal, sheet, select, date picker, alert dialog out of the box; best fit for Tailwind + Vite + React 18 stack |
| RD-25 | Badge color palette | 10 named colors, fixed list | gray, blue, yellow, green, red, orange, purple, pink, teal, indigo mapped to Tailwind classes in colors.js; users pick from swatches, no free-form hex; sufficient variety for status/priority defaults and team member badges |
| RD-26 | Automated testing | None in v1 — manual testing only | Solo portfolio project; visual verification against live Supabase dev instance is the most reliable test for this app's risk surface; intentional decision documented to distinguish from oversight |
| RD-27 | Vercel SPA routing | vercel.json rewrite rule committed in Phase 1 | Prevents 404 on direct navigation to /board/:slug in production; trivial to add upfront, painful to debug in Phase 12 |
| RD-28 | Schema migration strategy | Manual numbered SQL files via Supabase SQL Editor | supabase/migrations/ is source of truth; run files in order to rebuild; appropriate for solo project with infrequent schema changes; no CLI tooling required |

## **10.2 Open Questions**

| ID | Question | Owner | Status |
| --- | --- | --- | --- |
| OQ-04 | Is there a maximum field count per board to keep the UI manageable? | Stephen Levy | Open |

# **Appendix**

## **A. Data Model**

Full schema documented in [001_initial_schema.sql](../supabase/migrations/001_initial_schema.sql). Key entities:

- **boards** — Top-level entity with unique slug for shared access. Name is editable; slug is immutable.
- **fields** — Configurable field definitions per board (name, field_key, field_type, options, display_order)
- **team_members** — People assignable to person-type fields
- **projects** — Cards with title (first-class column) + JSONB field_values for all configurable fields. New projects appended to bottom of column (display_order = max + 1).
- **comments** — Timestamped comments linked to projects. Immutable (no edit); delete supported.

## **B. Glossary**

| Term | Definition |
| --- | --- |
| field_key | Immutable identifier for a field, used as the key in projects.field_values JSONB. Distinct from the field's display name. |
| JSONB | PostgreSQL binary JSON type used to store flexible field values on each project |
| Slug | URL-safe string identifier for a board, used in the shared link (e.g., /board/product-project-board). Immutable after creation. |
| Pod | A sub-team or domain grouping within the PM team (e.g., Kubernetes, BuildTech, Cloud) |
| RLS | Row-Level Security — Supabase/Postgres feature controlling data access at the row level |
| Slugify | Convention for deriving a value key from a label: lowercase, replace spaces/special chars with underscores, strip non-alphanumeric. Used for option value keys and CSV import. |
