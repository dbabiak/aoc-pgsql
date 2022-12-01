\! ls inputs

drop table if exists d03_raw;
create table d03_raw (
    rownum serial primary key
  , line text not null
);

\! cat inputs/d03.txt | PGPASSWORD=tron psql -U dmb -h localhost -d dmb -c "copy d03_raw(line) from stdin"


drop table if exists d03;
create table d03 (
  rownum serial primary key
, bitvector int[] not null
);

insert into d03 (bitvector)
select string_to_array(line, null)::int[]
  from d03_raw
;


create or replace function mk_array(n int) returns int[] as $$
declare
  xs int[];
begin
  xs := array[]::int[];
  for _ in 1..n loop
    xs := array_append(xs, 0);
  end loop;
  return xs;
end;
$$ language plpgsql;

create or replace function pop_count() returns int[] as
$$
declare
    len int;
    xs int[];
    acc int[];
begin
    len := (select array_length(bitvector, 1) from d03 limit 1);
    acc := mk_array(len);
    for xs in select bitvector from d03 loop
        for i in 1..len loop
            acc[i] := acc[i] + xs[i];
        end loop;
    end loop;
    return acc;
end;
$$ language plpgsql;

drop function d3p1;
create or replace function d3p1() returns int as $$
declare
    popcnt int[];
    result int[];
    n int;
    i int;
    x int;
begin
    popcnt := pop_count();
    result := mk_array(array_length(popcnt, 1));
    raise notice 'popcnt: %', popcnt;
    raise notice 'result: %', result;
    n := (select count(*) from d03);
    for i in 1..array_length(popcnt, 1) loop
        case
        when 2*popcnt[i] < n then
            x := 0;
        else
            x:= 1;
        end case;
        result[i] := x;
    end loop;
    raise notice 'epsilon_rate %', epsilon_rate(result);
    raise notice 'gamma_rate %', gamma_rate(result);
    return epsilon_rate(result) * gamma_rate(result);
end;
$$ language plpgsql;

create or replace function to_decimal(xs int[]) returns int as $$
declare
    acc int := 0;
    i int;
    n int := array_length(xs, 1);
begin
    for i in 0..(array_length(xs, 1) - 1) loop
--         raise notice 'acc: %   i: %  xs[n - i]: %', acc, i, xs[n - i];
        acc := acc + xs[n - i] * 2^(i);
    end loop;
    return acc;
end;
$$ language plpgsql;

create or replace function gamma_rate(xs int[]) returns int as $$
declare
    ys int[] := mk_array(array_length(xs, 1));
    i int;
begin
    for i in 1..array_length(xs, 1) loop
        ys[i] := (xs[i] + 1) % 2;
    end loop;
    return to_decimal(ys);
end;
$$ language plpgsql;

create or replace function epsilon_rate(xs int[]) returns int as $$
begin
    return to_decimal(xs);
end;
$$ language plpgsql;

select d3p1();
-- do $$
-- declare
--   row d03%rowtype;
--   x int;
-- begin
--  for row in select * from d03
--  loop
--    raise notice 'row %', row;
--    foreach x in array row.bitvector
--    loop
--      raise notice '       x %', x;
--    end loop;
--  end loop;
-- end;
-- $$ LANGUAGE plpgsql;
