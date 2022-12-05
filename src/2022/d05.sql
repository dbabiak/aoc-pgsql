
drop table if exists d05_raw cascade;
create table d05_raw (
  line_num serial primary key
, line text
);

\copy d05_raw (line) from './inputs/2022/d05.input';

select * from d05_raw limit 10;

create or replace function get_n_cols() returns int as $$
    select (regexp_match(line, '(\d+)\s*$'))[1]::int
      from d05_raw
     where line_num = (
        select min(line_num) from d05_raw where line like '%1%'
     );
$$ language sql;

drop table if exists stacks cascade;
create table stacks (
  stack_id int primary key
, crates text
);

with cols as (
    select n.n as col from generate_series(1, get_n_cols()) n(n)
)
insert into stacks (stack_id, crates)
select col as stack_id
     , trim(string_agg(substring(line, 2 + 4 * (col - 1), 1), '' order by line_num desc)) as crates
  from d05_raw
  cross join cols
  where line_num < (select min(line_num) from d05_raw where line like '%1%')
  group by col
  order by col
;


drop table if exists instructions cascade;
create table instructions (
  instruction_id serial primary key
, raw text
, n int
, from_stack int
, to_stack int
, applied bool default false
);

with _ as (
select line_num, line, regexp_match(line, '^move (\d) from (\d) to (\d)$')::int[] as xs
  from d05_raw
 where line_num > 1 + (select min(line_num) from d05_raw where line like '%1%')
)
insert into instructions (n, from_stack, to_stack, raw)
select xs[1], xs[2], xs[3], line
  from _
 order by line_num;

select * from instructions limit 5;


create or replace function evaluate_instruction(
instruction instructions
) returns void as $$
declare
    from_stack stacks%rowtype;
    to_stack stacks%rowtype;
    len int;
begin
    select * from stacks where stack_id = instruction.from_stack into from_stack;
    select * from stacks where stack_id = instruction.to_stack into to_stack;
--     if (length(from_stack.crates) - instruction.n) < 0 then
--         raise notice 'instruction %', instruction.raw;
--         raise notice 'from_stack %', from_stack;
--         raise notice 'to_stack %', to_stack;
--         raise exception 'not enough crates in from_stack';
--     end if;

    len := least(length(from_stack.crates), instruction.n);

    update stacks
       set crates = crates || substr(reverse((
         select crates from stacks where stack_id = instruction.from_stack
      )), 1, len)
     where stack_id = instruction.to_stack;

    update stacks
       set crates = substr(crates, 1, length(crates) - len)
     where stack_id = instruction.from_stack;

    update instructions
       set applied = true
     where instruction_id = instruction.instruction_id;
end;
$$ language plpgsql;


create or replace function d5p1() returns void as $$
declare
    instruction instructions%rowtype;
begin
    for instruction in select * from instructions order by instruction_id loop
--         raise notice 'instruction %', instruction.raw;
        perform evaluate_instruction(instruction);
    end loop;
end;
$$ language plpgsql;

create or replace function eval_next_instruction() returns void as $$
declare
  instruction instructions%rowtype;
begin
    select *
      from instructions
     where not applied
     order by instruction_id
     limit 1
      into instruction;

    perform evaluate_instruction(instruction);
end;
$$ language plpgsql;


select * from stacks order by stack_id;
\timing
select d5p1();
\timing off
select * from stacks order by stack_id;

select string_agg(substr(crates, length(crates), 1), '' order by stack_id)
  from stacks
;
