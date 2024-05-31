import torch

from ..utils import get_critical
from ..utils import act 
from ..utils import find_changes
from ..utils import forward
from ..utils import Moves
from .. import objective

import sys 

class delta_tnn:
    def __init__(self, s, l, v):
        self.s = s 
        self.l = l 
        self.v = v 
        self.u_indices = torch.nonzero(s.W_search[l][:, v], as_tuple = True)[0] # Select weights indices part of search 
        self.w_values = s.W[l][:, self.v][self.u_indices] # Select weight values corresponding to indices part of search
        self.moves = self.find_moves()
        
    
    def find_moves(self):
        if self.l == 0 or self.l > self.s.settings.L:
            raise ValueError(f"l must be between 1 and {self.s.settings.L}")
        elif len(self.u_indices) == 0: # No weights going into this node are part of the search 
            return None 
        elif self.l < self.s.settings.L: # We are looking at a weight going into a hidden layer
            self.critical = get_critical(self.s, self.l, self.v)
            if len(self.critical) == 0: # No reason to consider any change in any of the weights, as no activations will change 
                delta_weight_values_list, req_weights_list = self.get_delta_weight_values(self.w_values)
                weights = torch.cat([self.u_indices, self.u_indices])
                final_delta_weight_values = torch.cat([delta_weight_values_list[0], delta_weight_values_list[1]])
                final_req_weights_list = torch.cat([-req_weights_list[0], -req_weights_list[1]])
                delta_objectives = torch.zeros(final_delta_weight_values.shape)
                return Moves(self.l, self.v, weights, delta_objectives, final_delta_weight_values)
            self.u_prev = torch.clone(self.s.U[self.l - 1][self.critical, :])[:, self.u_indices] # Get the reduced activation matrix from the previous layer
            self.u = torch.clone(self.s.U[self.l][self.critical, self.v]) # Get the current activations for this node for the critical instances 
            self.S = torch.clone(self.s.S[self.l][self.critical, self.v]) # Get the current preactivation values for this node for the critical instances 
            self.S_next = torch.clone(self.s.S[self.l + 1][self.critical, :]) # Get the current preactivation values for the next layer for the critical instances 
            return self.find_moves_hidden()
        else:
            return self.find_moves_last()

    # Function that return a list of moves
    def find_moves_hidden(self):
        l, critical = self.l, self.critical 
        current_weights = self.w_values
        delta_weight_values_list, req_weights_list = self.get_delta_weight_values(current_weights)
        delta_changes = self.calculate_delta_changes(critical)
        # delta_changes is a vector that says by how much the objective function value will change if the activation of the instance corresponding to that index changes
        weights = torch.cat([self.u_indices, self.u_indices])
        delta_objectives = torch.zeros(2 * len(self.u_indices))
        final_delta_weight_values = torch.zeros(2 * len(self.u_indices), dtype = torch.int32)
        counter = 0 
        for delta_weight_values_vector in delta_weight_values_list:
            z = torch.clone(self.S).unsqueeze(1).repeat(1, len(self.u_indices)) + self.u_prev * delta_weight_values_vector.view(1, len(self.u_indices))
            # z is the new preactivation values, where each column corresponds to the new preactivation values if the corresponding weight was 'flipped'
            activation_changes = find_changes(act(z), self.u) # A matrix where each column corresponds to the changes in activation if the corresponding weight was 'flipped'
            deltas = (delta_changes.unsqueeze(1) * activation_changes).sum(dim = 0) - req_weights_list[counter]  # A tensor with the total objective function value change for each weight if it was 'flipped'
            delta_objectives[counter* len(self.u_indices) : (counter + 1)* len(self.u_indices)] = deltas 
            final_delta_weight_values[counter* len(self.u_indices) : (counter + 1)* len(self.u_indices)] = delta_weight_values_vector
            counter += 1 
        return Moves(self.l, self.v, weights, delta_objectives, final_delta_weight_values)

    # Function that return a list of moves
    def find_moves_last(self):
        l = self.l
        current_weights = self.w_values
        delta_weight_values_list, req_weights_list = self.get_delta_weight_values(current_weights)
        plus_one = self.calculate_delta_changes_last(1) # What happens if the preactivation increases by 1
        plus_two = self.calculate_delta_changes_last(2) # What happens if the preactivation increases by 2
        minus_one = self.calculate_delta_changes_last(-1) # What happens if the preactivation decreases by 1
        minus_two = self.calculate_delta_changes_last(-2) # What happens if the preactivation decreases by 2
        weights = torch.cat([self.u_indices, self.u_indices])
        delta_objectives = torch.zeros(2 * len(self.u_indices))
        final_delta_weight_values = torch.zeros(2 * len(self.u_indices), dtype = torch.int32)
        counter = 0 
        for delta_weight_values_vector in delta_weight_values_list:
            change = self.s.U[self.l - 1][:, self.u_indices]* delta_weight_values_vector # Calculate the change to the preactivation values if the weights are 'flipped'
            result = torch.zeros_like(change, dtype = torch.float32) + (change == 1) * plus_one.view(-1, 1) + (change == 2) * plus_two.view(-1, 1) + (change == -1) * minus_one.view(-1, 1) + (change == -2) * minus_two.view(-1, 1)
            deltas = torch.sum(result, axis = 0) - req_weights_list[counter]
            delta_objectives[counter* len(self.u_indices) : (counter + 1)* len(self.u_indices)] = deltas 
            final_delta_weight_values[counter* len(self.u_indices) : (counter + 1)* len(self.u_indices)] = delta_weight_values_vector
            counter += 1 
        return Moves(self.l, self.v, weights, delta_objectives, final_delta_weight_values)
    
    # Function that calculate the changes in objective values if the activations change - used for the hidden layers
    def calculate_delta_changes(self, critical):
        l = self.l 
        delta = -2 * torch.clone(self.u).unsqueeze(1)
        z = torch.clone(self.S_next) + torch.mul(delta, self.s.W[l + 1][self.v, :])
        l += 1
        while l < self.s.settings.L:
            u = act(z) 
            l += 1
            z = forward(u, self.s.W[l])
        o = objective.Objective_Manager(self.s.settings)
        return o.calculate_objective(z, self.s.batch.Y[critical]) - self.s.O[critical]

    # Function that calculate the changes in objective values if the activations change - used for the final layer
    def calculate_delta_changes_last(self, delta_weight_value):
        o = objective.Objective_Manager(self.s.settings)
        z = torch.clone(self.s.S[self.l])
        z[:, self.v] += delta_weight_value
        return o.calculate_objective(z, self.s.batch.Y) - self.s.O

    
    def get_delta_weight_values(self, current_weights):
        delta_weight_values_list = []
        delta_weight_values = torch.where(current_weights == -1, 1, torch.where(current_weights == 0, -1, -2))
        delta_weight_values_list.append(delta_weight_values)
        delta_weight_values = torch.where(current_weights == -1, 2, torch.where(current_weights == 0, 1, -1))
        delta_weight_values_list.append(delta_weight_values)
        req_weights_list = []
        req_weights = torch.where(current_weights == -1, -1, torch.where(current_weights == 0, 1, 0)) * self.s.settings.reqularization_parameter
        req_weights_list.append(req_weights)
        req_weights = torch.where(current_weights == -1, 0, torch.where(current_weights == 0, 1, -1)) * self.s.settings.reqularization_parameter
        req_weights_list.append(req_weights)
        return delta_weight_values_list, req_weights_list
