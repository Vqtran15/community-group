-- Migration 06: Multi-tenancy — scopes all data to the authenticated community group account
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor
--
-- IMPORTANT: Read the instructions at the bottom before AND after running this.

-- 1. Add user_id to all data tables (auto-fills with auth.uid() on every insert)
alter table meal_pages      add column if not exists user_id uuid references auth.users(id) default auth.uid();
alter table signups         add column if not exists user_id uuid references auth.users(id) default auth.uid();
alter table serving_pages   add column if not exists user_id uuid references auth.users(id) default auth.uid();
alter table serving_signups add column if not exists user_id uuid references auth.users(id) default auth.uid();
alter table birthdays       add column if not exists user_id uuid references auth.users(id) default auth.uid();

-- 2. Drop the old "allow everything" policies
drop policy if exists "public read/write" on meal_pages;
drop policy if exists "public read/write" on signups;
drop policy if exists "public read/write" on serving_pages;
drop policy if exists "public read/write" on serving_signups;
drop policy if exists "public read/write" on birthdays;

-- 3. Ensure RLS is enabled
alter table meal_pages      enable row level security;
alter table signups         enable row level security;
alter table serving_pages   enable row level security;
alter table serving_signups enable row level security;
alter table birthdays       enable row level security;

-- 4. New policies — each user only sees their own community group's data
create policy "owner" on meal_pages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "owner" on signups
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "owner" on serving_pages
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "owner" on serving_signups
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "owner" on birthdays
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- 5. Enable realtime for all data tables (scoped to authenticated user via RLS)
alter publication supabase_realtime add table meal_pages, serving_pages, birthdays;
-- Note: signups and serving_signups were already added in earlier migrations

-- ─────────────────────────────────────────────────────────────────────────────
-- BEFORE RUNNING: In Supabase dashboard → Authentication → Settings:
--   • Disable "Enable email confirmations" for instant sign-in after signup
--     (otherwise users must click a confirmation link first)
--
-- AFTER RUNNING:
--   1. Open the app → you'll see a sign-in page
--   2. Create your community group account
--   3. Find your user ID: Supabase dashboard → Authentication → Users → copy UUID
--   4. Run the following in SQL Editor to claim your existing data:
--
--      update meal_pages      set user_id = 'PASTE-YOUR-UUID-HERE' where user_id is null;
--      update signups         set user_id = 'PASTE-YOUR-UUID-HERE' where user_id is null;
--      update serving_pages   set user_id = 'PASTE-YOUR-UUID-HERE' where user_id is null;
--      update serving_signups set user_id = 'PASTE-YOUR-UUID-HERE' where user_id is null;
--      update birthdays       set user_id = 'PASTE-YOUR-UUID-HERE' where user_id is null;
-- ─────────────────────────────────────────────────────────────────────────────
