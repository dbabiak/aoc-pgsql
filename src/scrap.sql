drop table if exists xs;
create table xs (x int);

\copy xs from './src/d01.txt' with csv;

-- select array_agg(x) from xs;

-- create or replace function tron(
--     nums int[]
-- ) returns int as $$
-- declare
--   i int;
--   x int;
-- begin
--     i := 0;
--     foreach x in array nums loop
--       raise notice 'i: % x: %', i, x;
--       i := i + 1;
--     end loop;
--     return 42;
-- end;
-- $$ language plpgsql;


create or replace function window_sum(
  nums int[]
, i int
) returns int as $$
begin
    return nums[i] + nums[i + 1] + nums[i + 2];
end;
$$ language plpgsql;

create or replace function tron_2(
    nums int[]
) returns int as $$
declare
  i int;
  acc int := 0;
begin
    raise notice 'len: %', array_length(nums, 1);
    for i in array_lower(nums, 1)..(array_upper(nums, 1) - 3) loop
      if window_sum(nums, i) < window_sum(nums, i + 1) then
        acc := acc + 1;
      end if;
    end loop;
    return acc;
end;
$$ language plpgsql;

select tron_2(array_agg(x)) from xs;
