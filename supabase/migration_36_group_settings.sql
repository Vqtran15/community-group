-- Migration 36: Create group_settings table with RLS
-- Stores per-group configuration (rotation schedule, guide URL, sample data flag).
-- Previously missing — app was silently failing to persist these settings.
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. group_settings table — one row per community group
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists group_settings (
  group_id              uuid primary key references community_groups(id) on delete cascade,
  guide_url             text,
  meal_day_of_week      int  check (meal_day_of_week between 0 and 6),
  meal_interval_days    int  check (meal_interval_days > 0),
  service_autofill      boolean not null default false,
  service_interval_days int  check (service_interval_days > 0),
  service_day_of_week   int  check (service_day_of_week between 0 and 6),
  sample_seeded         boolean not null default false,
  updated_at            timestamptz default now()
);

alter table group_settings enable row level security;

-- Members can read and write their own group's settings only
create policy "group members" on group_settings
  for all
  using  (group_id = current_community_group_id())
  with check (group_id = current_community_group_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Fix legacy tables: app_settings and serving_settings
-- These are pre-multitenancy singleton tables no longer used by the app.
-- Replace the fully-open "public read/write" policy with an admin-only guard
-- so they can't be read or written by regular users of any group.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "public read/write" on app_settings;
drop policy if exists "public read/write" on serving_settings;

create policy "deny all" on app_settings      for all using (false);
create policy "deny all" on serving_settings  for all using (false);
