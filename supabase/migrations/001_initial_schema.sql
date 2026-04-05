-- ============================================================
-- PM Team Board — Initial Schema
-- Run in Supabase SQL Editor
-- ============================================================

-- Enable UUID generation
create extension if not exists "pgcrypto";

-- ============================================================
-- TABLES
-- ============================================================

create table boards (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table fields (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references boards(id) on delete cascade,
  name text not null,
  field_key text not null,
  field_type text not null check (field_type in ('text', 'single_select', 'date', 'person', 'url')),
  options jsonb default '[]'::jsonb,
  display_order integer not null default 0,
  is_required boolean default false,
  is_default boolean default false,
  created_at timestamptz default now(),
  unique (board_id, field_key)
);

create table team_members (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references boards(id) on delete cascade,
  name text not null,
  color text,
  created_at timestamptz default now()
);

create table projects (
  id uuid primary key default gen_random_uuid(),
  board_id uuid not null references boards(id) on delete cascade,
  title text not null,
  field_values jsonb default '{}'::jsonb,
  display_order integer default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table comments (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references projects(id) on delete cascade,
  author_name text not null,
  body text not null,
  created_at timestamptz default now()
);

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_fields_board_id on fields(board_id);
create index idx_team_members_board_id on team_members(board_id);
create index idx_projects_board_id on projects(board_id);
create index idx_comments_project_id on comments(project_id);
create index idx_boards_slug on boards(slug);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================

create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger boards_updated_at
  before update on boards
  for each row execute function update_updated_at();

create trigger projects_updated_at
  before update on projects
  for each row execute function update_updated_at();

-- ============================================================
-- ROW-LEVEL SECURITY
-- ============================================================
-- v1: anon key has full read/write access to all tables.
-- Policies use `using (true)` — there is no board_id scoping at the RLS layer.
-- The non-guessable board slug embedded in the shared link is the only access
-- control in v1. v2 will add individual auth and board-membership-scoped policies.

alter table boards enable row level security;
alter table fields enable row level security;
alter table team_members enable row level security;
alter table projects enable row level security;
alter table comments enable row level security;

create policy "boards_select" on boards for select using (true);
create policy "boards_insert" on boards for insert with check (true);
create policy "boards_update" on boards for update using (true);
create policy "boards_delete" on boards for delete using (true);

create policy "fields_select" on fields for select using (true);
create policy "fields_insert" on fields for insert with check (true);
create policy "fields_update" on fields for update using (true);
create policy "fields_delete" on fields for delete using (true);

create policy "team_members_select" on team_members for select using (true);
create policy "team_members_insert" on team_members for insert with check (true);
create policy "team_members_update" on team_members for update using (true);
create policy "team_members_delete" on team_members for delete using (true);

create policy "projects_select" on projects for select using (true);
create policy "projects_insert" on projects for insert with check (true);
create policy "projects_update" on projects for update using (true);
create policy "projects_delete" on projects for delete using (true);

create policy "comments_select" on comments for select using (true);
create policy "comments_insert" on comments for insert with check (true);
create policy "comments_update" on comments for update using (true);
create policy "comments_delete" on comments for delete using (true);

-- ============================================================
-- SEED: Default board with pre-configured fields
-- ============================================================

-- Create default board
insert into boards (id, name, slug)
values ('00000000-0000-0000-0000-000000000001', 'Product Project Board', 'product-project-board');

-- Seed default fields
insert into fields (board_id, name, field_key, field_type, options, display_order, is_default) values
  ('00000000-0000-0000-0000-000000000001', 'Status', 'status', 'single_select',
   '[{"value": "not_started", "label": "Not Started", "color": "gray"},
     {"value": "in_progress", "label": "In Progress", "color": "blue"},
     {"value": "in_review", "label": "In Review", "color": "yellow"},
     {"value": "completed", "label": "Completed", "color": "green"}]'::jsonb,
   1, true),

  ('00000000-0000-0000-0000-000000000001', 'Priority', 'priority', 'single_select',
   '[{"value": "p1_high", "label": "P1 - High", "color": "red"},
     {"value": "p2_medium", "label": "P2 - Medium", "color": "orange"},
     {"value": "p3_low", "label": "P3 - Low", "color": "green"}]'::jsonb,
   2, true),

  ('00000000-0000-0000-0000-000000000001', 'Owner', 'owner', 'person', '[]'::jsonb, 3, true),

  ('00000000-0000-0000-0000-000000000001', 'Pod', 'pod', 'single_select', '[]'::jsonb, 4, true),

  ('00000000-0000-0000-0000-000000000001', 'Start Date', 'start_date', 'date', '[]'::jsonb, 5, true),

  ('00000000-0000-0000-0000-000000000001', 'Target Completion', 'target_completion', 'date', '[]'::jsonb, 6, true),

  ('00000000-0000-0000-0000-000000000001', 'Description', 'description', 'text', '[]'::jsonb, 7, true);
