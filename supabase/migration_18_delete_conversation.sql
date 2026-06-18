-- Migration 18: RPC to delete a conversation
-- Cascades to messages, reactions, and conversation_members automatically.
-- Prevents deleting the main group conversation (the one with all members).
-- Run in Supabase SQL Editor

create or replace function delete_conversation(conv_id uuid)
returns void language plpgsql security definer
set search_path = public as $$
declare
  conv             record;
  conv_member_count int;
  group_member_count int;
begin
  if not is_conversation_member(conv_id) then
    raise exception 'Not a member of this conversation';
  end if;

  select * into conv from conversations where id = conv_id;

  -- Block deletion of the main group conversation
  if conv.type = 'group' then
    select count(*) into conv_member_count
      from conversation_members where conversation_id = conv_id;
    select count(*) into group_member_count
      from profiles where community_group_id = conv.community_group_id;
    if conv_member_count >= group_member_count then
      raise exception 'Cannot delete the main group conversation';
    end if;
  end if;

  -- Deleting the conversation cascades to messages → reactions and conversation_members
  delete from conversations where id = conv_id;
end;
$$;
