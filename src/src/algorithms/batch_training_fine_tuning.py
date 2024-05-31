from ..solution import Solution
from ..solvers.solvers import * 
from ..evaluation import Evaluation
from ..utils import get_moves_dict
from ..utils import Weight 
from ..utils import Move
from .. import delta 

from time import perf_counter
import torch 
import random

import sys 
# @profile 
def batch_training_fine_tuning(instance, settings, time_left):
    print("Was here")
    e = Evaluation(instance)
    threshold = settings.threshold
    p = settings.bernoulli_parameter
    update_interval_start = settings.update_interval_start
    update_interval_end = settings.update_interval_end
    update_interval_increase_interval = settings.update_interval_increase
    update_interval = update_interval_start

    total_counter = 0
    total_update_counter = 0 
    start = perf_counter()
    counter = 0
    loader = instance.loader('train', settings.batch_size)
    batch = next(loader)
    counter += 1
    total_counter += 1
    s = Solution(batch, settings)

    s.random_solution()
    s.select_search_weights(p)



    moves_dict = get_moves_dict(s)
    
    while time_left - (perf_counter() - start) > 0 :
        # print(s.obj_value(), total_counter)
        # print(e.training_accuracy(s.batch, s.S[settings.L]))
        d = delta.Delta_Manager(s)

        for node in s.nodes:
            moves = d.delta_calculation(node.l, node.v)
            if moves is not None:
                moves_dict[(node.l, node.v)]['delta_objectives'] += moves.delta_objectives
        if counter == update_interval:
            s.logging['moves_per_update'].append(0)
            s.logging['train_accuracies'].append(0)
            s.logging['train_accuracies_before_update'].append(0)

            update_number = len(s.logging['moves_per_update']) - 1
            s.logging['train_accuracies_before_update'][update_number] = e.training_accuracy(s.batch, s.S[settings.L])
            counter = 0
            no_moves = 0 
            
            for l, v in moves_dict:
                max_delta = torch.max(moves_dict[(l, v)]['delta_objectives'])
                if max_delta.item() > threshold:
                    s.logging['moves_per_update'][update_number] += 1
                    max_indice = torch.argmax(moves_dict[(l, v)]['delta_objectives']).item()
                    u = moves_dict[(l, v)]['u_indices'][max_indice].item()
                    dw = moves_dict[(l, v)]['delta_weight_values'][max_indice].item()
                    move = Move(Weight(u, l, v), max_delta, dw)
                    s.commit_move(move)
                    no_moves += 1
            s.logging['train_accuracies'][update_number] = e.training_accuracy(s.batch, s.S[settings.L])

            
            

            # print(f'{no_moves} moves were committed')
            # print(s.n_connections)

            s.select_search_weights(p)
            moves_dict = get_moves_dict(s)
            total_update_counter += 1 
            if total_update_counter % update_interval_increase_interval == 0:
                update_interval = min(update_interval + 1, update_interval_end)
                total_update_counter = 0
        


        counter += 1
        total_counter += 1
        try:
            batch = next(loader)
        except StopIteration:
            loader = instance.loader('train', settings.batch_size)
            batch = next(loader)
        s.change_batch(batch)


    return s 


