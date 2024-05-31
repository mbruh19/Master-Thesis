from time import perf_counter
import torch 
import random

from .. import delta 
from ..utils import Move
from ..utils import Weight

from .. import objective

import sys 

def iterated_improvement(solution, time_budget, threshold = 0):
    if solution.settings.logging == True:
        ii_number = len(solution.logging['iterated_improvement_moves'])
        solution.logging['iterated_improvement_moves'].append(0)
        
    start = perf_counter()
    d = delta.Delta_Manager(solution)
    while perf_counter() - start < time_budget: 
        random.shuffle(solution.nodes)
        improvement_found = False
        for node in solution.nodes:
            moves = d.delta_calculation(node.l, node.v)
            if moves is None:
                continue
            max_delta = torch.max(moves.delta_objectives)
            max_indice = torch.argmax(moves.delta_objectives).item()
            best_weight = Weight(moves.u_indices[max_indice].item(), moves.l, moves.v)
            best_move = Move(best_weight, max_delta, moves.delta_weight_values[max_indice])
            if best_move.delta_objective > threshold:
                solution.commit_move(best_move)
                improvement_found = True
                if solution.settings.logging == True:
                    solution.logging['iterated_improvement_moves'][ii_number] += 1
            if perf_counter() - start >= time_budget:
                return solution 
        if improvement_found == False:
            return solution
    return solution

