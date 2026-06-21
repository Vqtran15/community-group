-- Migration 24: Reversible admin promotion/demotion
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

create or replace function set_member_role(target_user_id uuid, new_role text)
returns void language plpgsql security definer set search_path = public as $$
declare
  grp_id uuid := current_community_group_id();
begin
  if not is_group_admin() then
    raise exception 'Only admins can change member roles';
  end if;
  if new_role not in ('member', 'admin') then
    raise exception 'Invalid role';
  end if;
  if not exists (
    select 1 from profiles where user_id = target_user_id and community_group_id = grp_id
  ) then
    raise exception 'User is not in your group';
  end if;
  -- Prevent leaving the group with no admin
  if new_role = 'member' and (
    select count(*) from profiles where community_group_id = grp_id and role = 'admin'
  ) <= 1 then
    raise exception 'There must be at least one admin in the group';
  end if;
  update profiles set role = new_role
  where user_id = target_user_id and community_group_id = grp_id;
end;
$$;
