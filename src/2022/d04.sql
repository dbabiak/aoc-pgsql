\! find . -name d04.sample

create temporary table d04_raw (
  line_num serial primary key
, line text
);

\copy d04_raw (line) from './inputs/2022/d04.input';

select * from d04_raw limit 10;

create temporary table d04 (
  line_num int primary key
, first int4range
, second int4range
);

with _ as (
select line_num
     , line
     , regexp_split_to_array(line, '[-,]')::int[] as xs
  from d04_raw
)
insert into d04 (line_num, first, second)
select line_num
     , int4range(xs[1], xs[2], '[]') as first
     , int4range(xs[3], xs[4], '[]') as second
  from _
order by line_num
;

select * from d04 limit 10;


\timing
with p1 as (
    select *
      from d04
     where first  <@ second
        or second <@ first
)
select count(*)
  from p1;


with p2 as (
    select *
    from d04
    where first && second
)
select count(*)
from p2;
