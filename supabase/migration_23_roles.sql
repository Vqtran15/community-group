-- Migration 23: Group admin roles
-- Run in Supabase SQL Editor: https://app.supabase.com → SQL Editor

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Add role column; default everyone to 'member'
-- ─────────────────────────────────────────────────────────────────────────────
alter table profiles
  add column role text not null default 'member'
  check (role in ('member', 'admin'));

-- 2. Promote the earliest member of each group to admin (the group creator)
update profiles p
set role = 'admin'
where created_at = (
  select min(created_at) from profiles p2
  where p2.community_group_id = p.community_group_id
);

-- 3. Allow group members to read each other's profiles (needed for member list + role badges)
do $$ begin
  create policy "view group members" on profiles
    for select using (community_group_id = current_community_group_id());
exception when duplicate_object then null;
end $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Update handle_new_user: group creators get 'admin', joiners get 'member'
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  grp_id    uuid;
  grp_name  text := trim(new.raw_user_meta_data->>'community_group_name');
  inv_code  text := upper(trim(new.raw_user_meta_data->>'invite_code'));
  disp_name text := trim(new.raw_user_meta_data->>'display_name');
  usr_role  text := 'member';
  new_code  text;
begin
  if disp_name is null or disp_name = '' then return new; end if;

  if inv_code is not null and inv_code <> '' then
    select id into grp_id from community_groups where invite_code = inv_code;
    if grp_id is null then
      raise exception 'Invalid invite code. Please check with your group leader.';
    end if;

  elsif grp_name is not null and grp_name <> '' then
    if exists (select 1 from community_groups where name = grp_name) then
      raise exception 'A group with that name already exists. Use an invite code to join it.';
    end if;
    loop
      new_code := upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 6));
      exit when not exists (select 1 from community_groups where invite_code = new_code);
    end loop;
    insert into community_groups (name, invite_code)
    values (grp_name, new_code)
    returning id into grp_id;
    usr_role := 'admin';

  else
    return new;
  end if;

  insert into profiles (user_id, community_group_id, display_name, role)
  values (new.id, grp_id, coalesce(nullif(disp_name, ''), 'Member'), usr_role);

  return new;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Helper: check if the current user is an admin in their group
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function is_group_admin()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from profiles where user_id = auth.uid() and role = 'admin'
  )
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. RPC: rotate_invite_code — admin only, returns the new code
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function rotate_invite_code()
returns text language plpgsql security definer set search_path = public as $$
declare
  new_code text;
begin
  if not is_group_admin() then
    raise exception 'Only admins can rotate the invite code';
  end if;
  loop
    new_code := upper(substring(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (select 1 from community_groups where invite_code = new_code);
  end loop;
  update community_groups set invite_code = new_code where id = current_community_group_id();
  return new_code;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 7. RPC: remove_member — admin only, deletes profile and conversation membership
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function remove_member(target_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare
  grp_id uuid := current_community_group_id();
begin
  if not is_group_admin() then
    raise exception 'Only admins can remove members';
  end if;
  if auth.uid() = target_user_id then
    raise exception 'You cannot remove yourself';
  end if;
  if not exists (
    select 1 from profiles
    where user_id = target_user_id and community_group_id = grp_id
  ) then
    raise exception 'User is not in your group';
  end if;
  -- Remove from all conversations in this group
  delete from conversation_members
  where user_id = target_user_id
    and conversation_id in (
      select id from conversations where community_group_id = grp_id
    );
  -- Delete profile (revokes all group data access)
  delete from profiles where user_id = target_user_id and community_group_id = grp_id;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 8. RPC: rename_group — admin only
-- ─────────────────────────────────────────────────────────────────────────────
create or replace function rename_group(new_name text)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_group_admin() then
    raise exception 'Only admins can rename the group';
  end if;
  if trim(new_name) = '' then
    raise exception 'Group name cannot be empty';
  end if;
  update community_groups set name = trim(new_name) where id = current_community_group_id();
end;
$$;
