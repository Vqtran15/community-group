-- Migration 17: Allow anonymous users to read community group names
-- Needed so the signup page can show a dropdown of existing groups
-- Run in Supabase SQL Editor

create policy "public read group names" on community_groups
  for select to anon using (true);
