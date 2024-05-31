from ..solution import Solution 
from ..solvers.solvers import * 
from time import perf_counter 

def single_batch(instance, settings, time_left):

    start = perf_counter()

    loader = instance.loader('train', settings.batch_size) 

    batch = next(loader) 

    s = Solution(batch, settings) 

    s.random_solution()

    if settings.solver == "ils":
        s = ils(s, time_left - (perf_counter() - start), settings.perturbation_size)
        # s = ils_node(s, 10, settings.perturbation_size)
        pass
    elif settings.solver == "iterated_improvement":
        s = iterated_improvement(s, time_left - (perf_counter() - start), threshold = settings.threshold)

    return s