from ..solution import Solution 
from ..solvers.solvers import * 
from time import perf_counter 
from ..utils import Node
from ..delta import Delta_Manager
def delta_example(instance, settings, time_left):

    start = perf_counter()

    loader = instance.loader('train', settings.batch_size) 

    batch = next(loader) 

    s = Solution(batch, settings) 

    s.random_solution()

    for l in s.S:
        print(f's[{l}]: {s.S[l]}')

    for l in s.U:
        print(f'u[{l}]: {s.U[l]}')

    d = Delta_Manager(s)
    n = Node(2, 3)

    moves = d.delta_calculation(n.l, n.v)


    print(moves)



    return s