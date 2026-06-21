-- Migration 21: Security fixes — M1, M2, M3, M4
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- ─────────────────────────────────────────────────────────────────────────────
-- M1: Storage delete — the existing "owner delete" policy was correct but the
--     upload path had convId as the first folder, so foldername(name)[1]
--     never matched auth.uid(). The frontend now uploads to
--     {myId}/{convId}_{timestamp}.{ext}, so this policy works as intended.
--     No SQL change needed — path fix is in ChatView.jsx.
-- ─────────────────────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────────────────────
-- M2: Storage MIME type enforcement — restrict the bucket to image types only
--     and tighten the insert policy with an extension check.
-- ─────────────────────────────────────────────────────────────────────────────
update storage.buckets
set allowed_mime_types = array[
  'image/jpeg', 'image/jpg', 'image/png', 'image/gif',
  'image/webp', 'image/heic', 'image/heif', 'image/avif'
]
where id = 'chat-images';

drop policy if exists "authenticated upload" on storage.objects;

create policy "authenticated upload" on storage.objects
  for insert with check (
    bucket_id = 'chat-images'
    and auth.uid() is not null
    and lower(storage.extension(name)) in
      ('jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'avif')
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- M3: Reactions — split FOR ALL; restrict DELETE to reaction owner only.
-- ─────────────────────────────────────────────────────────────────────────────
drop policy if exists "group members" on reactions;

create policy "reactions select" on reactions
  for select using (community_group_id = current_community_group_id());

create policy "reactions insert" on reactions
  for insert with check (
    community_group_id = current_community_group_id()
    and user_id = auth.uid()
  );

create policy "reactions delete" on reactions
  for delete using (user_id = auth.uid());

-- ─────────────────────────────────────────────────────────────────────────────
-- M4: display_name impersonation — overwrite the client-supplied display_name
--     with the verified value from profiles before the row is inserted.
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function enforce_message_display_name()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  select display_name into new.display_name
  from profiles
  where user_id = auth.uid();
  return new;
end;
$$;

drop trigger if exists enforce_display_name on messages;

create trigger enforce_display_name
  before insert on messages
  for each row execute function enforce_message_display_name();
