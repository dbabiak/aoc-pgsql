import os

input()
os.system('clear')

def execute(query) -> None:
    os.system(
        f"PGPASSWORD=tron psql -h localhost -p 5432 -U dmb -c '{query}'"
    )

def step():
    execute('select * from instructions where not applied order by instruction_id limit 1;')
    execute('select * from stacks order by stack_id;')
    execute('select eval_next_instruction();')
    execute('select * from stacks order by stack_id;')

while True:
    step()
    input()
    os.system('clear')
