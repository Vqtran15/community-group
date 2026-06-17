-- Migration 07: Individual accounts per community group
-- Each person has their own login; everyone in the same group shares data.
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- 1. Community groups table
create table if not exists community_groups (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  created_at timestamptz default now()
);

-- 2. Profiles table — links each auth user to a group and stores their display name
create table if not exists profiles (
  user_id            uuid primary key references auth.users(id) on delete cascade,
  community_group_id uuid not null references community_groups(id),
  display_name       text not null,
  created_at         timestamptz default now()
);

-- 3. Trigger: when a new user signs up, auto-create their group (if new) and profile.
--    Reads community_group_name and display_name from user_metadata set during signUp.
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  grp_id    uuid;
  grp_name  text := new.raw_user_meta_data->>'community_group_name';
  disp_name text := new.raw_user_meta_data->>'display_name';
begin
  if grp_name is null or grp_name = '' then return new; end if;

  -- Insert group; if the name already exists, get the existing row's id
  insert into community_groups (name) values (grp_name) on conflict (name) do nothing;
  select id into grp_id from community_groups where name = grp_name;

  -- Create the user's profile
  insert into profiles (user_id, community_group_id, display_name)
  values (new.id, grp_id, coalesce(nullif(trim(disp_name), ''), 'Member'));

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure handle_new_user();

-- 4. Helper: returns the current authenticated user's community_group_id
create or replace function current_community_group_id()
returns uuid language sql stable security definer set search_path = public as $$
  select community_group_id from profiles where user_id = auth.uid()
$$;

-- 5. Add community_group_id to all data tables (auto-fills from the user's profile on insert)
alter table meal_pages      add column if not exists community_group_id uuid references community_groups(id) default current_community_group_id();
alter table signups         add column if not exists community_group_id uuid references community_groups(id) default current_community_group_id();
alter table serving_pages   add column if not exists community_group_id uuid references community_groups(id) default current_community_group_id();
alter table serving_signups add column if not exists community_group_id uuid references community_groups(id) default current_community_group_id();
alter table birthdays       add column if not exists community_group_id uuid references community_groups(id) default current_community_group_id();

-- 6. Enable RLS on new tables
alter table community_groups enable row level security;
alter table profiles         enable row level security;

-- 7. RLS: community groups — members see only their own group
create policy "view own group" on community_groups
  for select using (id = current_community_group_id());

-- 8. RLS: profiles — users manage only their own profile
create policy "manage own profile" on profiles
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 9. Replace old user_id-based policies with community_group_id-based ones
drop policy if exists "owner" on meal_pages;
drop policy if exists "owner" on signups;
drop policy if exists "owner" on serving_pages;
drop policy if exists "owner" on serving_signups;
drop policy if exists "owner" on birthdays;

create policy "group members" on meal_pages
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

create policy "group members" on signups
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

create policy "group members" on serving_pages
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

create policy "group members" on serving_signups
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

create policy "group members" on birthdays
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- AFTER RUNNING: migrate your existing account (b169b5cc-c617-4c65-881d-4ac1b58b500a)
--
-- Step A — Create your community group and note the returned id:
--   insert into community_groups (name) values ('Lake Oswego & SE') returning id;
--
-- Step B — Create your profile (replace GROUP-ID and Your Name):
--   insert into profiles (user_id, community_group_id, display_name)
--   values ('b169b5cc-c617-4c65-881d-4ac1b58b500a', 'GROUP-ID', 'Your Name');
--
-- Step C — Claim your existing data (replace GROUP-ID):
--   update meal_pages      set community_group_id = 'GROUP-ID' where community_group_id is null;
--   update signups         set community_group_id = 'GROUP-ID' where community_group_id is null;
--   update serving_pages   set community_group_id = 'GROUP-ID' where community_group_id is null;
--   update serving_signups set community_group_id = 'GROUP-ID' where community_group_id is null;
--   update birthdays       set community_group_id = 'GROUP-ID' where community_group_id is null;
--
-- New signups going forward are handled automatically by the trigger.
-- ─────────────────────────────────────────────────────────────────────────────
