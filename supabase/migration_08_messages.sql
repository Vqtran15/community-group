-- Migration 08: Chat messages + image storage
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- 1. Messages table
create table messages (
  id                 uuid primary key default gen_random_uuid(),
  community_group_id uuid not null references community_groups(id) on delete cascade,
  user_id            uuid not null references auth.users(id),
  display_name       text not null,
  body               text,
  image_url          text,
  created_at         timestamptz default now(),
  constraint message_has_content check (body is not null or image_url is not null)
);

-- 2. RLS: group members can read and write their group's messages
alter table messages enable row level security;

create policy "group members" on messages
  for all using (community_group_id = current_community_group_id())
  with check (community_group_id = current_community_group_id());

-- 3. Realtime for live chat
alter publication supabase_realtime add table messages;

-- 4. Storage bucket for chat images
insert into storage.buckets (id, name, public) values ('chat-images', 'chat-images', true)
on conflict (id) do nothing;

-- Allow authenticated users to upload images
create policy "authenticated upload" on storage.objects
  for insert with check (bucket_id = 'chat-images' and auth.uid() is not null);

-- Allow anyone to view images (they are publicly referenced by URL in messages)
create policy "public read" on storage.objects
  for select using (bucket_id = 'chat-images');

-- Allow users to delete their own uploads
create policy "owner delete" on storage.objects
  for delete using (bucket_id = 'chat-images' and auth.uid()::text = (storage.foldername(name))[1]);
