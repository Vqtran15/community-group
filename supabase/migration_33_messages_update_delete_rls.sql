-- Migration 33: Add missing UPDATE and enforce DELETE policy for messages.
-- Without an UPDATE policy, message editing silently fails.
-- Authors can only edit/delete their own messages.

drop policy if exists "messages update" on messages;
drop policy if exists "messages delete" on messages;

create policy "messages update" on messages
  for update
  using  (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "messages delete" on messages
  for delete using (user_id = auth.uid());
