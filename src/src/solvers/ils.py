from time import perf_counter
import torch 

from .iterated_improvement import iterated_improvement

def ils(solution, time_budget, ps):
    if solution.settings.logging == True:
        log = True
        batch_number = len(solution.logging["local_optimas"])
        solution.logging['local_optimas'].append(0)
    else:
        log = False 
    
    start = perf_counter()
    best_weights = solution.copy_weights()
    best_obj = solution.obj_value()
    while perf_counter() - start < time_budget:
        solution = iterated_improvement(solution, time_budget - (perf_counter() - start), threshold = 0)
        obj = solution.obj_value()
        if obj < best_obj: 
            solution.W = {l: torch.clone(best_weights[l]) for l in best_weights}
            solution.evaluate()
        elif obj > best_obj:
            # print(solution.obj_value(True))
            best_weights = solution.copy_weights()
            best_obj = obj 
        solution.perturb(ps)
        if log:
            solution.logging['local_optimas'][batch_number] += 1 
        
    if solution.obj_value() < best_obj:
        solution.W = {l: torch.clone(best_weights[l]) for l in best_weights}
        solution.evaluate()
    return solution