-- Add announcement field to community_groups
alter table community_groups
  add column if not exists announcement text;

-- RPC so only admins can update it
create or replace function update_announcement(p_text text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not is_group_admin() then
    raise exception 'Only admins can update the announcement';
  end if;
  update community_groups
  set announcement = nullif(trim(p_text), '')
  where id = current_community_group_id();
end;
$$;
