import torch

from ..utils import get_critical
from ..utils import act 
from ..utils import find_changes
from ..utils import forward
from ..utils import Moves
from .. import objective

import sys 

class delta_bnn:
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
            # print(self.critical)
            if len(self.critical) == 0: # No reason to consider any change in any of the weights, as no activations will change 
                return Moves(self.l, self.v, self.u_indices, torch.zeros(self.u_indices.shape), -2 * self.w_values)
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
        delta_weight_values_vector = -2 * self.w_values # How much each weight will change if it is 'flipped' 
        # print(self.w_values)
        # print(delta_weight_values_vector)
        # print(self.u_prev)
        # print(torch.clone(self.S).unsqueeze(1).repeat(1, len(self.u_indices)))
        delta_changes = self.calculate_delta_changes(critical)
        # delta_changes is a vector that says by how much the objective function value will change if the activation of the instance corresponding to that index changes
        z = torch.clone(self.S).unsqueeze(1).repeat(1, len(self.u_indices)) + self.u_prev * delta_weight_values_vector.view(1, len(self.u_indices))
        # print(z)
        # print(delta_changes)
        
        # z is the new preactivation values, where each column corresponds to the new preactivation values if the corresponding weight was 'flipped'
        activation_changes = find_changes(act(z), self.u) # A matrix where each column corresponds to the changes in activation if the corresponding weight was 'flipped'
        # print((delta_changes.unsqueeze(1) * activation_changes))
        deltas = (delta_changes.unsqueeze(1) * activation_changes).sum(dim = 0) # A tensor with the total objective function value change for each weight if it was 'flipped'
        return Moves(self.l, self.v, self.u_indices, deltas, delta_weight_values_vector)

    # Function that return a list of moves
    def find_moves_last(self):
        l = self.l
        delta_weight_values_vector = -2 * self.w_values # How much each weight will change if it is 'flipped' 
        plus_changes = self.calculate_delta_changes_last(2) # What happens if the preactivation increases by 2 
        minus_changes = self.calculate_delta_changes_last(-2) # What happens if the preactivation decreases by 2
        change = self.s.U[self.l - 1][:, self.u_indices]* delta_weight_values_vector # Calculate the change to the preactivation values if the weights are 'flipped' 
        result = torch.zeros_like(change, dtype = torch.float32) + (change > 0) * plus_changes.view(-1, 1)  + (change < 0) * minus_changes.view(-1, 1)
        # Result is a matrix where each row corresponds to an instance, and each column a weight and the elements are the change in objective if that weight is 'flipped' for each instance
        deltas = torch.sum(result, axis = 0) # A tensor with the total objective function value change for each weight if it was 'flipped'
        return Moves(self.l, self.v, self.u_indices, deltas, delta_weight_values_vector)

    
    # Function that calculate the changes in objective values if the activations change - used for the hidden layers
    def calculate_delta_changes(self, critical):
        l = self.l 
        # print(self.S_next)
        # print(self.s.W[l + 1][self.v, :])
        delta = -2 * torch.clone(self.u).unsqueeze(1)
        # print(delta)
        # print(torch.mul(delta, self.s.W[l + 1][self.v, :]))
        z = torch.clone(self.S_next) + torch.mul(delta, self.s.W[l + 1][self.v, :])
        # print(z)
        l += 1
        while l < self.s.settings.L:
            u = act(z) 
            # print(u)
            l += 1
            z = forward(u, self.s.W[l])
        # print(z)
        o = objective.Objective_Manager(self.s.settings)
        # print(self.s.batch.Y[critical])
        # print(self.s.S[self.s.settings.L][critical])
        # print(o.calculate_objective(z, self.s.batch.Y[critical]) - self.s.O[critical])
        # print(self.s.O[critical])
        return o.calculate_objective(z, self.s.batch.Y[critical]) - self.s.O[critical]

    # Function that calculate the changes in objective values if the activations change - used for the final layer
    def calculate_delta_changes_last(self, delta_weight_value):
        o = objective.Objective_Manager(self.s.settings)
        z = torch.clone(self.s.S[self.l])
        z[:, self.v] += delta_weight_value
        return o.calculate_objective(z, self.s.batch.Y) - self.s.O