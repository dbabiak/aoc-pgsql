create or replace function kill(pid int) returns boolean as $$
begin
    return pg_terminate_backend(pid);
end;
$$ language plpgsql;
