
drop table if exists d02_raw;
create table d02_raw (
    line text
);

\copy d02_raw from 'src/d02.txt' with csv;


drop table if exists d02;
create table d02 (
    rownum serial primary key
  , direction text not null
  , n int not null
);

with input as (
  select string_to_array(line, ' ') arr from d02_raw
)
insert into d02 (direction, n)
select arr[1], (arr[2])::int
  from input;

-- select * from d02 limit 5;

create or replace function d02_part1() returns int as $$
declare
  X int := 0;
  depth int := 0;
  row d02%rowtype;
begin

  for row in select * from d02 order by rownum loop
    case row.direction
    when 'forward' then X := X + row.n;
    when 'up' then depth := depth - row.n;
    when 'down' then depth := depth + row.n;
    else raise exception 'unknown direction %', row.direction;
    end case;
  end loop;

  raise notice 'X: %, depth: %', X, depth;

  return X * depth;
end;
$$ language plpgsql;

select d02_part1();

create or replace function d02_part2() returns int as $$
declare
  X int := 0;
  depth int := 0;
  aim int := 0;
  row d02%rowtype;
begin
--     raise notice 'X: %, depth: %', X, depth;
    for row in select * from d02 order by rownum loop
        case row.direction
        when 'down' then aim := aim + row.n;
        when   'up' then aim := aim - row.n;
        when 'forward' then
            X := X + row.n;
            depth := depth + aim * row.n;
        else raise exception 'unknown direction %', row.direction;
        end case;
--         raise notice 'X: %, depth: %, aim %', X, depth, aim;
    end loop;

--     raise notice 'X: %, depth: %', X, depth;

    return X * depth;
end;
$$ language plpgsql;

\timing
select d02_part2();


