-- Migration 10: Shared public notes per community group
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- 1. Add notes column to community_groups
alter table community_groups add column if not exists notes text default '';

-- 2. Ensure RLS is enabled on community_groups
alter table community_groups enable row level security;

-- 3. Allow members to read their own group (needed to fetch notes)
do $$ begin
  create policy "members can read own group" on community_groups
    for select using (id = current_community_group_id());
exception when duplicate_object then null;
end $$;

-- 4. Allow members to update their group's notes
do $$ begin
  create policy "members can update group notes" on community_groups
    for update using (id = current_community_group_id())
    with check (id = current_community_group_id());
exception when duplicate_object then null;
end $$;
