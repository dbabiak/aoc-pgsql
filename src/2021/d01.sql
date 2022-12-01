
drop table if exists xs;
create table xs (x int);

\copy xs from './src/d01.sql.txt' with csv;

with i_x as (
  select row_number() over () as rownum, * from xs
)
select count(*)
  from i_x ix
  join i_x _ix on (ix.rownum + 1 = _ix.rownum)
  where ix.x < _ix.x
  ;


with i_x as (
  select row_number() over () as rownum, * from xs
)
, sums as (
    select rownum
    , (
      x
    + lead(x, 1) over (order by rownum)
    + lead(x, 2) over (order by rownum)
) as acc
  from i_x
  order by rownum
)
select count(*)
  from sums
  join sums _sums on (sums.rownum + 1 = _sums.rownum)
  where sums.acc < _sums.acc
