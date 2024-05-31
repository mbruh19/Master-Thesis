import torch
from .instance import Batch

import sys 

def act(x):
    return torch.where(x < 0, -1, 1).to(torch.int32)

def forward(u, w):
    return torch.mm(u, w)

def get_critical(s, l, v):
    max_value = s.batch.max_value
    if l == 1:
        condition = (s.S[l][:, v] < 2*max_value) & (s.S[l][:, v] > -2 * max_value - 1)
    else:
        condition = (s.S[l][:, v] < 2) & (s.S[l][:, v] > -3)
    return torch.where(condition)[0]

# Function to find out what values have changed. u can simply be a 1D tensor, while new_u often is a 2D. 
def find_changes(new_u, u, unsqueeze = True):
    if unsqueeze:
        return torch.ne(new_u, u.unsqueeze(1))
    else:
        return torch.ne(new_u, u)

def get_binary_train_data(instance, settings):
    loader = instance.loader("train", settings.batch_size)
    batch = next(loader)
    train_data = {}
    for i in range(instance.n_labels()):
        indices = (batch.Y == i).nonzero(as_tuple = False)
        data = torch.clone(batch.X[indices, :].squeeze(1))
        labels = batch.Y[indices].squeeze(1)
        train_data[i] = Batch(data, labels)
    return train_data

def neural_network_evaluator(input_data, weights, numbers):
    l = 1 
    U = torch.clone(input_data).unsqueeze(0)
    while l <= len(weights):
        S = forward(U, weights[l])
        U = act(S)
        l += 1 
    if U[0] == 1:
        return numbers[0]
    else:
        return numbers[1]

def get_moves_dict(solution, nodes = None):
    if nodes == None:
        nodes = solution.nodes
    moves_dict = {}
    if solution.settings.network_type == "BNN":
        for node in nodes:
            l, v = node.l, node.v 
            
            if torch.sum(solution.W_search[l][:, v]) == 0:
                pass 
            else:
                moves_dict[(l, v)] = {}
                u_indices = torch.nonzero(solution.W_search[l][:, v], as_tuple = True)[0]
                moves_dict[(l, v)]['delta_objectives'] = torch.zeros(int(torch.sum(solution.W_search[l][:, v]).item()))
                moves_dict[(l, v)]['u_indices'] = u_indices
                weight_values = solution.W[l][:, v][u_indices]
                moves_dict[(l, v)]['delta_weight_values'] = -2 * weight_values
        return moves_dict
    elif solution.settings.network_type == "TNN":
        for node in nodes:
            l, v = node.l, node.v 
            
            if torch.sum(solution.W_search[l][:, v]) == 0:
                pass 
            else:
                moves_dict[(l, v)] = {}
                u_indices = torch.nonzero(solution.W_search[l][:, v], as_tuple = True)[0]
                weight_values = solution.W[l][:, v][u_indices]
                moves_dict[(l, v)]['delta_objectives'] = torch.zeros(2* int(torch.sum(solution.W_search[l][:, v]).item()))
                moves_dict[(l, v)]['u_indices']= torch.cat([u_indices, u_indices])
                delta_weight_values_list = get_delta_weight_values(weight_values)
                final_delta_weight_values = torch.cat([delta_weight_values_list[0], delta_weight_values_list[1]])
                moves_dict[(l, v)]['delta_weight_values'] = final_delta_weight_values
        return moves_dict
    else:
        raise ValueError(f'Not yet implemented')

def get_delta_weight_values(current_weights):
    delta_weight_values_list = []
    delta_weight_values = torch.where(current_weights == -1, 1, torch.where(current_weights == 0, -1, -2))
    delta_weight_values_list.append(delta_weight_values)
    delta_weight_values = torch.where(current_weights == -1, 2, torch.where(current_weights == 0, 1, -1))
    delta_weight_values_list.append(delta_weight_values)
    return delta_weight_values_list

class Node:
    def __init__(self, l, v):
        self.l = l 
        self.v = v

    def __str__(self):
        return f"Node with l={self.l} and v={self.v}"

class Move:
    def __init__(self, weight, delta_objective, delta_weight_value):
        self.weight =  weight 
        self.delta_objective = delta_objective
        self.delta_weight_value = delta_weight_value

    def __str__(self):
        return f"Move with {self.weight}, change in objective value = {self.delta_objective} and change in value = {self.delta_weight_value}"

class Moves:
    def __init__(self, l, v, u_indices, delta_objectives, delta_weight_values):
        self.l = l
        self.v = v
        self.u_indices = u_indices 
        self.delta_objectives = delta_objectives
        self.delta_weight_values = delta_weight_values 

    def __str__(self):
        return f"Moves for layer {self.l} and neuron {self.v} with u-indices {self.u_indices} and delta objectives {self.delta_objectives} and the values of the weights change by {self.delta_weight_values}"


class Weight:
    def __init__(self, u, l, v):
        self.u = u 
        self.l = l 
        self.v = v 

    def __str__(self):
        return f"Weight going from neuron {self.u} in layer {self.l - 1} to neuron {self.v} in layer {self.l}"