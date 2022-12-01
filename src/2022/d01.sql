drop table if exists d01_raw;
create table d01_raw (
  line_num serial primary key
, line text
);

\copy d01_raw (line) from 'inputs/2022/d01.input';

-- select * from d01_raw;

drop table if exists d01;
create table d01 (
  elf_id int
, calories int
);

do $$
declare
  row d01_raw%rowtype;
  elf_id int := 0;
begin
    for row in select line_num, line from d01_raw order by line_num
    loop
        if row.line = '' then
            elf_id := elf_id + 1;
            continue;
        end if;

        insert into d01 (elf_id, calories)
        values (elf_id, (row.line)::int);
    end loop;
end;
$$ language plpgsql;

-- select * from d01;

\timing
-- d01 part 1
select elf_id, sum(calories) from d01 group by elf_id order by 2 desc limit 1;


select 'd01 part2';
-- d01 part 2
with _ as (select elf_id, sum(calories) as total_cals from d01 group by elf_id order by 2 desc limit 3)
select sum(total_cals) from _;
