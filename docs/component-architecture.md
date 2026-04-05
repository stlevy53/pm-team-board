# PM Team Board — Component Architecture

## Routing

Single-page app with one meaningful route:

```
/board/:slug    → Board view (shared link entry point)
/               → Redirect to /board/product-project-board (v1 is single-board-per-deployment)
```

No auth routes needed for v1. The slug in the URL is the access control. Board creation via the UI is a backlog item for v2.

## Project Structure

```
src/
├── lib/
│   ├── supabase.js              # Supabase client init
│   └── database.js              # All Supabase queries (single module)
│
├── hooks/
│   ├── useBoard.js              # Loads board + fields + team members
│   ├── useProjects.js           # CRUD for projects, scoped to board
│   └── useComments.js           # CRUD for comments, scoped to project
│
├── components/
│   ├── Board/
│   │   ├── BoardShell.jsx       # Top-level layout: header, view tabs, content area
│   │   ├── ViewTabs.jsx         # Data-driven tab bar derived from board field schema
│   │   └── BoardHeader.jsx      # Board name, settings button, CSV import/export
│   │
│   ├── Kanban/
│   │   ├── KanbanView.jsx       # Receives grouping field, renders columns
│   │   ├── KanbanColumn.jsx     # Single column: header + droppable card list
│   │   └── KanbanCard.jsx       # Card preview: title, owner badge, priority tag
│   │
│   ├── Table/
│   │   ├── TableView.jsx        # Full table with sortable/filterable columns
│   │   ├── TableHeader.jsx      # Column headers with sort controls
│   │   ├── TableRow.jsx         # Single project row
│   │   └── TableFilter.jsx      # Filter bar: per-field dropdowns, active filter badges
│   │
│   ├── Card/
│   │   ├── CardDetailModal.jsx  # Full-screen or slide-out project detail
│   │   ├── FieldRenderer.jsx    # Renders a field value by type (text, select, date, person, url)
│   │   ├── FieldEditor.jsx      # Inline edit for each field type
│   │   └── CommentThread.jsx    # Comment list + add comment form + delete
│   │
│   ├── Settings/
│   │   ├── SettingsPanel.jsx    # Slide-out panel container
│   │   ├── FieldManager.jsx     # Add/edit/reorder/delete fields
│   │   ├── OptionEditor.jsx     # Manage single-select options (add, rename, recolor, reorder)
│   │   └── TeamManager.jsx      # Add/edit/remove team members
│   │
│   ├── Import/
│   │   ├── CSVImportModal.jsx   # Upload CSV, preview data
│   │   └── FieldMapper.jsx      # Map CSV columns → board fields
│   │
│   └── shared/
│       ├── Badge.jsx            # Colored badge for status, priority, owner, pod
│       ├── DatePicker.jsx       # Date field input
│       ├── SelectDropdown.jsx   # Single-select field input
│       ├── PersonPicker.jsx     # Team member selector
│       ├── EmptyState.jsx       # Zero-state messaging
│       └── ConfirmDialog.jsx    # Delete confirmations
│
├── utils/
│   ├── csv.js                   # CSV parse/serialize logic
│   ├── colors.js                # Named color palette → Tailwind class map (10 colors: gray, blue, yellow, green, red, orange, purple, pink, teal, indigo)
│   ├── slugify.js               # Label → value key conversion (used for options and CSV import)
│   └── fieldDefaults.js         # Default field definitions (mirrors DB seed)
│
├── vercel.json                  # SPA fallback: rewrites all routes to index.html
└── components.json              # shadcn/ui configuration
│
├── App.jsx                      # Router + global providers
└── index.jsx                    # Entry point
```

## Data Flow

### Board Load Sequence

```
1. URL parsed → extract slug
2. useBoard(slug) →
   a. fetchBoardBySlug(slug) → returns board record including board.id  [sequential — board.id required for next steps]
   b. fetchFields(board.id) + fetchTeamMembers(board.id)               [parallel — both depend only on board.id]
3. useProjects(board.id) →
   a. fetchProjects(board.id)
4. Board renders with all data in memory
5. Mutations (add/edit/delete/reorder) → Supabase call → refetch or optimistic update
```

Note: steps 2a and 2b are sequential by necessity — `board.id` is not available until `fetchBoardBySlug` resolves. Steps 2b run in parallel with each other once `board.id` is known.

### State Management

No Redux or global store. React context for board-level data, hooks for everything else.

```
BoardContext:
  - board (id, name, slug)
  - fields[] (schema definitions)
  - teamMembers[]
  - activeView (table | kanban:status | kanban:owner | kanban:priority | kanban:pod)

Projects managed via useProjects hook:
  - projects[]
  - addProject(title, fieldValues)
  - updateProject(id, changes)
  - deleteProject(id)
  - reorderProject(id, newOrder, newFieldValue?)  ← handles drag-and-drop

Table filtering is client-side only — no Supabase query. All projects are already in memory;
filtering is array manipulation on the local projects[] state. Filter state is not persisted.
```

## Component Responsibilities

### BoardShell
Owns the layout. Loads board data via useBoard, provides BoardContext. Renders ViewTabs + the active view component (TableView or KanbanView).

### KanbanView
Fully data-driven — receives a `groupByField` prop (a field definition object, not a hardcoded string). The component derives its columns entirely from data:

- **For single-select fields** (status, priority, pod, or any user-created field): columns come from the field's `options` array. Add a new option in Settings → a new column appears automatically.
- **For person fields** (owner): columns come from the `teamMembers` array in BoardContext. Add a new team member → a new column appears automatically.

This means KanbanView has zero knowledge of specific fields. It doesn't know what "Status" or "Pod" means — it only knows how to group cards by whatever field it's given. Two consequences:

1. **New options/people require no code changes.** Adding a team member, a new priority level, or a new pod creates a new column in the relevant kanban view immediately.
2. **New fields can become new views.** If a user creates a "Quarter" single-select field (Q1, Q2, Q3, Q4), the app can offer a "Quarter View" kanban with no new component code — just a new entry in ViewTabs pointing to that field.

### ViewTabs
Data-driven tab bar. Always includes a Table tab ("All Projects"). Kanban tabs are derived from the board's field schema — every single-select or person field is automatically available as a kanban grouping. Ships with default tabs for Status, Owner, Priority, and Pod, but any new single-select or person field added in Settings creates a new tab without code changes.

ViewTabs is data-driven from Phase 4 — it reads from `fields[]` in BoardContext, not from a hardcoded list. This ensures the tab system is correct from day one and avoids a later refactor.

Handles drag-and-drop between columns via the reorderProject function, which updates both display_order and the grouped field's value in a single Supabase call.

### TableView
Renders all projects in a flat table. Columns derived from `fields[]`. Sort state is local. Filter state is local — filtering is client-side array manipulation on the in-memory projects list, no Supabase query required. Clicking a row opens CardDetailModal.

### CardDetailModal
Renders all fields for a project using FieldRenderer (display) and FieldEditor (edit). Inline editing — click a field value to toggle to edit mode. Includes CommentThread at the bottom.

### SettingsPanel
Slide-out from the right. Three sections: Fields, Options (per single-select field), Team. All mutations go through the same Supabase query module.

### CSVImportModal
Two-step flow:
1. Upload CSV → parse headers and preview rows
2. FieldMapper shows CSV columns on the left, board fields on the right. User maps each column. Unmapped columns are ignored. Submit creates projects in batch.

For single-select fields, imported values are matched case-insensitively against existing options. Unmatched values are auto-created as new options using the slugify utility (`value` derived from label). New options are assigned a default gray color; user can recolor from Settings.

For person fields, imported names are matched against existing team members. Unmatched names are not created automatically — they are reported in the post-import summary so the user can manually assign those projects afterward.

## Drag-and-Drop

Using dnd-kit (`@dnd-kit/core`, `@dnd-kit/sortable`). When a card is dropped:

1. Identify source column (old field value) and target column (new field value)
2. If columns differ → update project's field_values with new value for the grouped field
3. Update display_order for all affected cards in the target column
4. Single Supabase call: update project with new field_values and display_order

## Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| State management | React Context + hooks | Overkill to add Redux for a single-board app with <100 items |
| Drag-and-drop lib | dnd-kit | Actively maintained, lightweight, accessible, works well with React 18 |
| Supabase queries | Single database.js module | All queries in one place — easy to audit, refactor, or swap if needed |
| View switching | Data-driven KanbanView + ViewTabs | One component handles all kanban views. ViewTabs derives available views from the board's fields — new single-select or person fields automatically become available as kanban groupings. Data-driven from Phase 4. |
| Table filtering | Client-side only | Projects already in memory; filtering is array manipulation. No additional Supabase query needed. Filter state not persisted. |
| CSV parsing | Client-side (Papaparse) | No server needed; handles edge cases well |
| Styling | Tailwind CSS | Fast iteration, consistent with modern React patterns |
| UI components | shadcn/ui | Radix UI primitives + Tailwind; copy-into-codebase model means no runtime dependency lock-in. Covers modal (Dialog), slide-out panel (Sheet), dropdown (Select), date picker (Popover + Calendar), confirm dialog (AlertDialog), and button. Custom components built for Badge (product-specific color logic), EmptyState, and PersonPicker (combobox with team member data). |
| Option value keys | Slugified from label | Lowercase + underscores, strip non-alphanumeric. Consistent with seed data pattern. |
| Badge color palette | 10 named colors mapped to Tailwind classes | Fixed set (gray, blue, yellow, green, red, orange, purple, pink, teal, indigo) covers status/priority defaults and team member variety. Users pick from swatches in Settings — no free-form hex input. Defined in `utils/colors.js`. |
| Automated testing | None in v1 | Solo portfolio project; no complex business logic that isn't immediately verifiable visually. Real risk surface is the Supabase integration, best validated by using the app against a live dev instance. Intentional decision — not an oversight. |
| SPA routing (Vercel) | `vercel.json` rewrite rule | Prevents 404 on direct navigation to `/board/:slug` in production. Committed in Phase 1. |
| Schema migrations | Manual via Supabase SQL Editor | Numbered migration files in `supabase/migrations/` run manually in the dashboard. Appropriate for solo project with infrequent schema changes. `supabase/migrations/` is the source of truth — run files in order to rebuild from scratch. |
