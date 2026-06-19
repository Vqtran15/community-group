-- Migration 19: Prayer Requests (community-group scoped)
-- Everyone in the same community group can see and add friends and prayer requests.
-- Follows the same pattern as birthdays (community_group_id via current_community_group_id()).
-- Run in Supabase SQL Editor

create table prayer_friends (
  id                 uuid primary key default gen_random_uuid(),
  community_group_id uuid not null default current_community_group_id() references community_groups(id),
  user_id            uuid references auth.users(id) on delete set null,
  added_by           text not null default '',
  name               text not null,
  created_at         timestamptz not null default now()
);
alter table prayer_friends enable row level security;
create policy "group members" on prayer_friends
  for all
  using  (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

create table prayer_requests (
  id                 uuid primary key default gen_random_uuid(),
  community_group_id uuid not null default current_community_group_id() references community_groups(id),
  friend_id          uuid not null references prayer_friends(id) on delete cascade,
  user_id            uuid references auth.users(id) on delete set null,
  added_by           text not null default '',
  date               date not null default current_date,
  request            text not null,
  created_at         timestamptz not null default now()
);
alter table prayer_requests enable row level security;
create policy "group members" on prayer_requests
  for all
  using  (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());
