create temporary table d02_raw (
  line_num int
, line text
);

\copy d02_raw (line) from 'inputs/2022/d02.input';

select * from d02_raw limit 10;

create temporary table d02 (
  line_num int
, their_raw text
, our_raw text
, their_move text
, our_move text
, result text
);

with input as (
    select line_num, string_to_array(line, ' ') as xs from d02_raw
)
insert into d02 (line_num, their_raw, our_raw, their_move, our_move, result)
select line_num
     , xs[1]
     , xs[2]
     , case xs[1]
      when 'A' then 'rock'
      when 'B' then 'paper'
      when 'C' then 'scissors'
      end
     , case xs[2]
           when 'X' then 'rock'
           when 'Y' then 'paper'
           when 'Z' then 'scissors'
    end
     , case xs[2]
           when 'X' then 'lose'
           when 'Y' then 'draw'
           when 'Z' then 'win'
    end
  from input
 order by line_num
;

select * from d02 limit 10;

-- or this could be a table...?
-- what else could it be?
create or replace function score_move(move text) returns int as $$
declare
    score int;
begin
    case move
        when 'rock'     then score := 1;
        when 'paper'    then score := 2;
        when 'scissors' then score := 3;
        else raise exception 'invalid move: %', move;
    end case;
    return score;
end;
$$ language plpgsql;

-- R < P < S < R
create or replace function score_round(their_move text, our_move text) returns int as $$
declare
    score int := 0;
begin
    if their_move = our_move then
        score := 3;
    else
        case their_move
            when 'rock'     then if our_move = 'paper' then score := 6; else score := 0; end if;
            when 'paper'    then if our_move = 'scissors' then score := 6; else score := 0; end if;
            when 'scissors' then if our_move = 'rock' then score := 6; else score := 0; end if;
            else raise exception 'invalid move: %', their_move;
        end case;
    end if;
    score := score + score_move(our_move);

    return score;
end;
$$ language plpgsql;

create or replace function score_result(result text) returns int as $$
    select case result
        when 'win'  then 6
        when 'draw' then 3
        when 'lose' then 0
    end;
$$ language sql;

select sum(score_round(their_move := d02.their_move, our_move := our_move)) from d02;

create temporary table rps (
  move     text
, beats    text
, loses_to text
);


insert into rps (move, beats, loses_to)
values ('rock', 'scissors', 'paper')
     , ('paper', 'rock', 'scissors')
     , ('scissors', 'paper', 'rock')
;

\timing
with xs as (select their_move
                 , result
                 , case result
                       when 'win' then loses_to
                       when 'draw' then move
                       when 'lose' then beats
        end as our_move
            from d02
                     join rps on (their_move = rps.move)
            order by line_num)
select sum(score_result(result) + score_move(our_move)) from xs;
;
