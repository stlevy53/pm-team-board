# PM Team Board — Backlog

Post-v1 features, ordered by priority. These items were explicitly deferred from v1 scope.

---

## Priority 1 — Build Next After v1 Launch

### Self-Serve Board Creation

**Problem:** v1 is single-board-per-deployment. A new team wanting their own board must fork the repo, run the SQL migration manually, and deploy. This is a barrier for non-technical users and limits the app's reach.

**Proposed solution:** Add a `/` landing page with a "Create your board" form. User enters a board name; a slug is auto-generated. Submitting calls `createBoard()`, runs the default field seed, and redirects to `/board/:slug`.

**What this requires:**
- New route: `/` with a board creation form
- `createBoard(name, slug)` function in `database.js`
- Seed logic triggered on board creation (currently SQL-only)
- Slug uniqueness validation and collision handling

**Why it was deferred:** Adds a new route, component, and DB function. Fork-and-deploy is acceptable for a portfolio project where deployment is controlled. Self-serve creation becomes important when the app is shared beyond the team.

---

### Comment Editing

**Problem:** Comments are immutable in v1. Users can delete a mistaken comment but cannot correct it. For longer comments or updates to context, users must delete and re-post.

**Proposed solution:** Add an edit button to each comment. Clicking switches the comment body to an inline text input. Saving calls `updateComment(id, body)`. Show an "edited" indicator on updated comments.

**What this requires:**
- `updateComment(id, body)` in `database.js`
- Inline edit state in `CommentThread.jsx`
- "Edited" visual indicator on the comment

**Why it was deferred:** Adds inline edit state complexity to the comment component. Delete covers the most urgent case (posting by mistake). Edit is a quality-of-life improvement for active discussion threads.

---

## Priority 2 — v2 Features

### Real-Time Collaborative Sync

Replace refresh-on-load with Supabase realtime subscriptions. Multiple team members can view and update the board simultaneously without overwriting each other's changes.

**Why deferred:** Refresh-on-load is acceptable for a small team. Supabase realtime is a low-effort integration once the data layer is stable.

---

### Individual Authentication & Activity Log

Add individual user accounts via Supabase Auth. Enables:
- Board-membership-scoped RLS (tightens the current permissive access model)
- Verified comment authorship (no more "who are you?" dropdown)
- Activity log showing who changed what and when
- Notification targets for email digests

**Why deferred:** Significantly expands scope. The shared-link trust model is sufficient for a small, known team in v1.

---

### Multi-Board Management

Allow a single deployment to host multiple boards. Adds a board dashboard at `/` listing all boards, with the ability to create, rename, and archive boards.

**Why deferred:** v1 is single-board-per-deployment by design. Multi-board requires individual auth to scope board access meaningfully.

---

### Additional Field Types

- **Multi-select:** Multiple values from a predefined list (e.g., tags, stakeholders)
- **Number:** Numeric values with optional formatting (e.g., story points, revenue impact)

**Why deferred:** Covers core PM workflow without these types. Multi-select adds complexity to JSONB queries and filter logic.

---

### Mobile-Responsive Layout

Adapt the layout for tablet and mobile viewports. Kanban columns become horizontally scrollable; table view collapses to a card list.

**Why deferred:** Kanban on mobile is a poor experience. Target users work from desktops. Mobile is a v2 concern if usage patterns change.
