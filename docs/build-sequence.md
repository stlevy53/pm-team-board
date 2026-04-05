# PM Team Board — Build Sequence

## Principles

Each phase should produce something testable. No phase depends on work that hasn't been completed in a prior phase. The sequence front-loads the data layer and core views so the board is usable early, then layers on configuration and import/export.

---

## Prerequisites (Before Phase 1)

These are one-time manual steps in the Supabase dashboard — not part of the code build sequence.

- Create a Supabase project at supabase.com
- Copy the project URL and anon key
- Store them as environment variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

Once credentials are in hand, Phase 1 can begin.

---

## Phase 1: Project Scaffolding

**Goal:** Empty React app running locally with Supabase connected.

- Initialize React project with Vite
- Install and configure Tailwind CSS
- Install Supabase JS client (`@supabase/supabase-js`)
- Create `lib/supabase.js` with client init (env vars for URL and anon key)
- Set up React Router with `/board/:slug` route and `/` redirect to `/board/product-project-board`
- Create placeholder `BoardShell.jsx` that renders the slug from the URL
- Confirm the app runs on localhost and connects to Supabase

**Depends on:** Prerequisites complete (Supabase project exists, anon key and URL available).

**Testable output:** App loads at `localhost:5173/board/product-project-board` and displays the slug.

---

## Phase 2: Supabase Schema

**Goal:** Database schema live with seed data.

- Run `001_initial_schema.sql` in the Supabase SQL Editor
- Verify tables, indexes, RLS policies, and seed data exist
- Confirm the default board and fields are queryable from the Supabase dashboard

**Depends on:** Prerequisites (Supabase project exists).

**Testable output:** Querying `boards` table returns the seeded "Product Project Board" row. Querying `fields` returns seven default fields.

---

## Phase 3: Data Layer & Hooks

**Goal:** All Supabase queries centralized in `database.js`; hooks fetch and expose board data.

- Create `lib/database.js` with all query functions (complete module — not split across phases):
  - **Board:** `fetchBoardBySlug(slug)`, `updateBoard(id, changes)`
  - **Projects:** `fetchProjects(boardId)`, `createProject(boardId, title, fieldValues, displayOrder)`, `updateProject(id, changes)`, `deleteProject(id)`, `reorderProject(id, displayOrder, fieldValues?)`
  - **Fields:** `fetchFields(boardId)`, `createField(boardId, fieldData)`, `updateField(id, changes)`, `deleteField(id)`, `reorderFields(updates)`
  - **Options:** `updateFieldOptions(fieldId, options)` (options array replaced wholesale)
  - **Team members:** `fetchTeamMembers(boardId)`, `createTeamMember(boardId, name, color)`, `updateTeamMember(id, changes)`, `deleteTeamMember(id)`
  - **Comments:** `fetchComments(projectId)`, `createComment(projectId, authorName, body)`, `deleteComment(id)`
- Create `hooks/useBoard.js` — fetches board + fields + team members by slug. Fetch sequence: `fetchBoardBySlug(slug)` first (sequential), then `fetchFields` + `fetchTeamMembers` in parallel once `board.id` is available.
- Create `hooks/useProjects.js` — CRUD for projects scoped to board
- Create `hooks/useComments.js` — CRUD and delete for comments scoped to project
- Create `BoardContext` for board-level data (board, fields, teamMembers, activeView)

**Depends on:** Phase 2 (database exists with seed data).

**Effort:** Large (full database.js module including all field, option, and team member mutations).

**Testable output:** `useBoard('product-project-board')` returns the board, seven fields, and empty team members array. Console-log confirms data flows from Supabase to React.

---

## Phase 4: Board Shell, Table View & Filter

**Goal:** First functional view — board loads by slug, table displays projects with sort and filter.

- Build `BoardShell.jsx`: header with board name, ViewTabs, content area
- Build `ViewTabs.jsx`: **data-driven from the start** — derives tabs from `fields[]` in BoardContext. Default tabs: All Projects (table), plus one kanban tab per single-select or person field. No hardcoded tab list.
- Build `BoardHeader.jsx`: board name display, "New" button, settings button placeholder
- Build `TableView.jsx`: renders all projects in a flat table
  - Columns derived from fields (display_order)
  - Person fields display team member name
  - Single-select fields display option label with color badge
- Build `TableHeader.jsx` with sort controls (ascending/descending toggle)
- Build `TableRow.jsx`
- Build `TableFilter.jsx`: filter bar with per-field dropdowns, active filter badges, "Clear all", filtered row count. **Client-side only** — filtering is array manipulation on in-memory projects, no Supabase query.
- Add project creation: "New" button opens a minimal form (title input), creates project via `useProjects`. New project appended to the bottom of its column (`display_order = max + 1`).
- Build shared components: `Badge.jsx`, `EmptyState.jsx`
- Implement empty state for zero projects

**Depends on:** Phase 3 (hooks and data layer).

**Testable output:** Board loads at `/board/product-project-board`. Table view shows columns for all default fields. Columns sort on header click. Filter bar filters projects client-side. User can create a project and see it appear at the bottom of the table. ViewTabs is data-driven (adding a field in Supabase directly creates a new tab without code changes).

---

## Phase 5: Card Detail Modal

**Goal:** Click a project to view and edit all fields inline.

- Build `CardDetailModal.jsx`: opens on row click (table) or card click (kanban, later)
- Build `FieldRenderer.jsx`: displays field values by type (text, badge, date, person name, clickable URL)
- Build `FieldEditor.jsx`: inline edit per type (text input, select dropdown, date picker, person picker, URL input)
- Build shared components: `SelectDropdown.jsx`, `DatePicker.jsx`, `PersonPicker.jsx`
- Wire edits to `updateProject` — persist on blur/confirmation
- Add delete button with `ConfirmDialog.jsx`

**Depends on:** Phase 4 (table view exists, projects can be created).

**Testable output:** Clicking a table row opens the detail modal. All fields display correctly. User can edit any field inline and see the change persist on reload. Delete removes the project.

---

## Phase 6: Kanban View (Status)

**Goal:** First kanban view — cards grouped by status, with drag-and-drop.

- Install dnd-kit (`@dnd-kit/core`, `@dnd-kit/sortable`)
- Build `KanbanView.jsx`: receives `groupByField` prop, derives columns from field options or team members
- Build `KanbanColumn.jsx`: column header (label + count), droppable card list
- Build `KanbanCard.jsx`: title, owner badge, priority badge, comment count
- Wire ViewTabs to render KanbanView with the status field when "Status" tab is active
- Implement drag-and-drop:
  - Cross-column drag updates the grouped field value
  - Same-column drag reorders (display_order)
  - Single Supabase call per drop
- Card click opens CardDetailModal (reuse from Phase 5)

**Depends on:** Phase 5 (card detail modal exists).

**Testable output:** Switching to "Status" tab shows status kanban with four columns. Cards appear in correct columns. Dragging a card to a different column updates its status. Clicking a card opens the detail modal.

---

## Phase 7: Remaining Kanban Views

**Goal:** Owner, Priority, and Pod views using the same KanbanView component.

- Wire ViewTabs to pass the correct field definition for each tab:
  - Owner View → owner field (person type, columns from teamMembers)
  - Priority View → priority field (single-select, columns from options)
  - Pod View → pod field (single-select, columns from options)
- Handle "Unassigned" column for projects missing a value for the grouped field
- Verify drag-and-drop works identically across all views

**Depends on:** Phase 6 (KanbanView component and drag-and-drop complete).

**Testable output:** All four kanban views render correctly. Dragging a card in Owner View changes the owner. Dragging in Priority View changes priority. Each view derives columns from data, not hardcoded values.

---

## Phase 8: Comments

**Goal:** Comment threads on project cards, with delete.

- Build `CommentThread.jsx`: displays comments chronologically with author name and relative timestamp
- Add comment form: team member selector + text input + submit button
- Add delete button per comment (with `ConfirmDialog`); wire to `deleteComment`
- Wire to `useComments` hook
- Add comment count badge to `KanbanCard.jsx` and `TableRow.jsx`
- Prevent submission of empty comments

**Depends on:** Phase 5 (card detail modal), Phase 3 (useComments hook).

**Testable output:** Opening a card shows comment thread. User can select their name, type a comment, and submit. Comment appears immediately with timestamp. User can delete a comment with confirmation. Comment count badge shows on the card in kanban and table views.

---

## Phase 9: Settings Panel

**Goal:** Configure fields, options, and team members from a slide-out panel.

- Build `SettingsPanel.jsx`: slide-out from right, three sections
- Build `FieldManager.jsx`:
  - Add field (name, type, display order)
  - Rename field (display name only; field_key immutable)
  - Rename board display name (board name editable; slug immutable)
  - Reorder fields (drag or arrow buttons)
  - Delete field (with confirmation, warning for defaults)
- Build `OptionEditor.jsx`:
  - Select a single-select field to manage
  - Add option (label + color); value key auto-derived via slugify utility
  - Rename, recolor, reorder, delete options
- Build `TeamManager.jsx`:
  - Add team member (name + color)
  - Edit name/color
  - Remove with confirmation (sets assigned projects to unassigned; existing comments preserved with old name)
- Wire settings button in BoardHeader
- Verify changes propagate to board views on panel close; new single-select/person fields appear as ViewTabs automatically

**Depends on:** Phase 7 (all views exist to verify propagation).

**Testable output:** Adding a team member in settings creates a new column in Owner View. Adding a priority option creates a new column in Priority View. Adding a new single-select field makes it available as a kanban view in ViewTabs automatically (data-driven). Renaming a field updates the table column header.

---

## Phase 10: CSV Export & Import

**Goal:** Export board as CSV. Import CSV with field mapping.

- Install Papaparse
- Build CSV export:
  - Serialize all projects with field display names as headers
  - Person fields export as names, single-select as labels
  - Trigger browser download
- Build `CSVImportModal.jsx`:
  - File upload, parse headers, preview first 5 rows
- Build `FieldMapper.jsx`:
  - Map CSV columns to board fields via dropdowns
  - "Skip" option for unmapped columns
- Implement batch project creation from mapped data:
  - Match single-select values case-insensitively against existing options; auto-create new options for unmatched values using slugify for the value key, default gray color
  - Match person names to existing team members; unmatched names reported in post-import summary (not auto-created)
  - Display summary: count created, any errors, list of projects with unmatched person values for manual follow-up

**Depends on:** Phase 9 (field/team configuration complete — needed for accurate mapping).

**Testable output:** Exporting the board produces a valid CSV that opens correctly in Excel/Sheets. Importing a Notion CSV export with field mapping creates projects with correct field values populated. Unmatched person names appear in the post-import summary.

---

## Phase 11: Polish & Error Handling

**Goal:** Production-quality UX for edge cases and first impressions.

- Empty states: no projects, no team members, no comments
- Loading states: skeleton/spinner during Supabase fetches
- Error states: invalid slug, failed Supabase calls, network errors
- Board header: finalize layout
- Keyboard accessibility: modal close on Escape, tab navigation
- Visual polish: consistent spacing, color palette, typography
- Favicon and page title

**Depends on:** All prior phases.

**Testable output:** Every screen has a non-blank state when empty. Network failures show a meaningful error. The app looks intentional, not scaffolded.

---

## Phase 12: Deploy to Vercel

**Goal:** Live at a public URL.

- Push to GitHub (repo: `pm-team-board`)
- Connect repo to Vercel
- Configure environment variables (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`)
- Configure SPA fallback for client-side routing
- Verify board loads at production URL
- Write README: problem, solution, tech stack, architecture decisions, screenshots, live demo link
- Document deployment model: v1 is single-board-per-deployment. New teams fork the repo, run `001_initial_schema.sql` in their own Supabase project, and deploy.

**Depends on:** Phase 11 (app is polished enough to deploy).

**Testable output:** Board is live at a public Vercel URL. Shared link works for team members. README is complete for portfolio presentation.

---

## Summary

| Phase | Deliverable | Effort |
|---|---|---|
| Pre | Supabase project setup (manual prerequisite) | Small |
| 1 | Project scaffolding | Small |
| 2 | Supabase schema | Small |
| 3 | Data layer & hooks (complete database.js) | Large |
| 4 | Board shell, table view & filter | Medium |
| 5 | Card detail modal | Medium |
| 6 | Kanban view (status) + drag-and-drop | Large |
| 7 | Remaining kanban views | Small |
| 8 | Comments (with delete) | Medium |
| 9 | Settings panel | Large |
| 10 | CSV export & import | Medium |
| 11 | Polish & error handling | Medium |
| 12 | Deploy to Vercel | Small |
