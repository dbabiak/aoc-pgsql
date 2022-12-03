create extension if not exists intarray;

select now();

\! find . -name d03.sample

create temporary table d03_raw (
  line_num bigserial primary key
, line text
);

\copy d03_raw (line) from './inputs/2022/d03.input';

create or replace function to_char_code(chr text) returns int as $$
declare
  is_upper bool;
begin
  is_upper := ascii(chr) between ascii('A') and ascii('Z');
  return ((ascii(chr) | 32) - ascii('a') + 1) + case when is_upper then 26 else 0 end;
end;
$$ language plpgsql;

create or replace function get_priorities(line text) returns int[] as $$
declare
    xs int[];
    chr text;
    i int;
begin
    for i in 1..length(line) loop
        chr := substring(line from i for 1);
        xs := array_append(xs, to_char_code(chr));
    end loop;
    return xs;
end;
$$ language plpgsql;

-- select chr(t.t), to_char_code(chr(t.t))
--   from generate_series(ascii('A'), ascii('Z')) as t
-- ;

select get_priorities('abc');

create temporary table d03 (
  line_num   bigserial primary key
, first_half int[]
, second_half int[]
, group_id int
);

with xs as (
select line_num
     , length(line) as len
     , line
  from d03_raw
)
insert into d03 (line_num, first_half, second_half, group_id)
select line_num
     , sort(get_priorities(substr(line, 1, len/2)))
     , sort(get_priorities(substr(line, 1 + len/2)))
     , ceil(line_num / 3.0)
  from xs
;

create or replace function p1() returns int[] as $$
declare
  xs int[];
  row d03%rowtype;
  x int;
begin

  <<outer>>
  for row in select * from d03 loop
      foreach x in array row.first_half loop
          if x = any(row.second_half) then
              xs := array_append(xs, x);
              continue outer;
          end if;
      end loop;
  end loop outer;

  return xs;
end;
$$ language plpgsql;

\timing
-- select sum(n) from unnest(p1()) as n;
-- select * from d03;

create or replace function p2() returns int[] as $$
declare
    g_id int;
    xs int[];
    x int;
begin
    for g_id in select distinct group_id from d03 order by group_id loop
        x := (
         select unnest(first_half || second_half) as n
           from d03
          where group_id = g_id
          group by 1
         having count(distinct line_num) = 3
        );
        xs := array_append(xs, x);
    end loop;

    return xs;
end;
$$ language plpgsql;

select sum(n) from unnest(p2()) as n;
