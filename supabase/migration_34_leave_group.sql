-- Migration 34: Allow members to leave the group.
-- Admins cannot leave if they are the sole admin (must promote first).

create or replace function leave_group()
returns void
language plpgsql
security definer
as $$
declare
  v_group_id uuid;
  v_role     text;
  v_admins   int;
begin
  select community_group_id, role
    into v_group_id, v_role
    from profiles
   where user_id = auth.uid();

  if v_role = 'admin' then
    select count(*) into v_admins
      from profiles
     where community_group_id = v_group_id
       and role = 'admin';

    if v_admins = 1 then
      raise exception 'You are the only admin. Promote another member before leaving.';
    end if;
  end if;

  delete from profiles where user_id = auth.uid();
end;
$$;
