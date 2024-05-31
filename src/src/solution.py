import torch 
import random

from . import objective

from .utils import act 
from .utils import forward
from .utils import find_changes
from .utils import Node
from .utils import Weight
from .utils import Move

import sys
class Solution:
    def __init__(self, batch, settings):
        self.batch = batch
        self.settings = settings 
        self.W = {l: torch.zeros(self.settings.network_structure[l-1], self.settings.network_structure[l], dtype = torch.int32) for l in range(1, self.settings.L + 1)}
        self.W_search = {l: torch.ones(self.settings.network_structure[l-1], self.settings.network_structure[l], dtype = torch.int32) for l in range(1, self.settings.L + 1)}
        self.S = {l: torch.zeros(self.batch.get_ninstances(), self.settings.network_structure[l], dtype = torch.int32) for l in range(1, self.settings.L + 1)}
        self.U = {l: torch.zeros(self.batch.get_ninstances(), self.settings.network_structure[l], dtype = torch.int32) for l in range(1, self.settings.L)}
        self.U[0] = self.batch.X
        self.O = torch.zeros(self.batch.get_ninstances(), dtype = torch.float64)
        self.weights = [Weight(u, l, v) for l in range(1, self.settings.L + 1) for v in range(self.settings.network_structure[l]) for u in range(self.settings.network_structure[l-1])]
        self.nodes = [Node(l, v) for l in range(1, self.settings.L + 1) for v in range(self.settings.network_structure[l])]
        self.weights_search = None

        
        if settings.logging == True:
            self.logging = {}
            self.logging['settings'] = vars(settings) # vars is used to convert the Namespace object (settings) to a dictionary that can be JSON serialized.
            self.logging['local_optimas'] = []
            self.logging['iterated_improvement_moves'] = []
            self.logging['moves_per_batch'] = [0]
            self.logging['total_moves']=0
            if settings.algorithm == 'batch_training_fine_tuning':
                self.logging['moves_per_update']=[]
                self.logging['train_accuracies']=[]
                self.logging['train_accuracies_before_update']=[]
            if settings.classification_type == 'binary':
                self.logging['connections_per_classifier'] = []
        
    def copy_weights(self):
        weights = {}
        for l in self.W:
            weights[l] = torch.clone(self.W[l])
        return weights 

    def random_solution(self, probabilities = None):
        if probabilities == None:
            if self.settings.network_type == "TNN":
                for l in self.W:
                    self.W[l] = torch.randint(low = -1, high = 2, size = self.W[l].shape, dtype = torch.int32)
            elif self.settings.network_type == "BNN":
                for l in self.W:
                    self.W[l] = 2 * torch.randint(low = 0, high = 2, size = self.W[l].shape, dtype = torch.int32) - 1 
            else:
                raise ValueError(f"'type' must be either 'TNN' or 'BNN'. Got: {self.settings.network_type}")
        else:
            p = torch.tensor(probabilities)
            if self.settings.network_type == "TNN":
                values = torch.tensor([-1, 0, 1], dtype = torch.int32)
            elif self.settings.network_type == "BNN":
                values = torch.tensor([-1, 1])
            for l in self.W:
                indices = torch.multinomial(p, self.W[l].numel(), replacement = True)
                self.W[l] = values[indices].reshape(self.W[l].shape)
        self.W[1] = self.W[1].to(self.U[0].dtype)
        self.evaluate()

    def evaluate(self):
        o = objective.Objective_Manager(self.settings)
        l = 1
        while l < self.settings.L:
            self.S[l] = forward(self.U[l-1], self.W[l])
            self.U[l] = act(self.S[l])
            l += 1 
        self.S[l] = forward(self.U[l-1], self.W[l])
        self.O = o.calculate_objective(self.S[l], self.batch.Y)

        if self.settings.network_type == 'TNN':
            counter = 0
            for l in self.W:
                counter += torch.sum(torch.abs(self.W[l]))
            self.n_connections = counter.item()
        else:
            self.n_connections = len(self.weights)

    def obj_value(self, printing = False):
        if self.settings.network_type == 'TNN':
            if printing:
                print(f'objective part {torch.sum(self.O).item()}, regularization part {-self.settings.reqularization_parameter * self.n_connections}')
            return torch.sum(self.O).item() - self.settings.reqularization_parameter * self.n_connections
        else:
            return torch.sum(self.O).item() 

    
    def commit_move(self, move):
        u, l, v, delta_weight_value = move.weight.u, move.weight.l, move.weight.v, move.delta_weight_value
        if self.settings.network_type == 'TNN':
            if self.W[l][u, v] == 0 and delta_weight_value != 0:
                self.n_connections += 1 
            elif self.W[l][u, v] + delta_weight_value == 0:
                self.n_connections += -1
        self.W[l][u, v] += delta_weight_value # Update the weight to its new value 
        if l == self.settings.L:
            self.update_last_layer(u, l, v, delta_weight_value)
        else:
            self.update_hidden_layer(u, l, v, delta_weight_value)
        
        if self.settings.logging == True:
            batch_number = len(self.logging['moves_per_batch'])
            self.logging['moves_per_batch'][batch_number - 1] += 1
            self.logging['total_moves']+= 1


    def update_last_layer(self, u, l, v, delta_weight_value):
        o = objective.Objective_Manager(self.settings)
        self.S[l][:, v] += torch.mul(delta_weight_value, self.U[l - 1][:, u]) # Update the preactivation values 
        self.O = o.calculate_objective(self.S[l], self.batch.Y) # Update the objectives

    def update_hidden_layer(self, u, l, v, delta_weight_value):
        o = objective.Objective_Manager(self.settings)
        old_activations = torch.clone(self.U[l][:, v]) # The activations before the update at this node 
        self.S[l][:, v] += torch.mul(delta_weight_value, self.U[l-1][:, u]) # Updating the preactivation values 
        self.U[l][:, v] = act(self.S[l][:, v]) # Updating the activations 
        changes = torch.where(find_changes(old_activations, self.U[l][:, v], unsqueeze = False)== 1)[0] # Find out what instances change activations 
        if len(changes) > 0: # Only necessary to propagate through the rest of the network, if there is some instances with changed activation
            l += 1 # Move one layer forward 
            while l < self.settings.L: # For the last layer, the binary activation function should not be used. 
                self.S[l][changes, :] = torch.mm(self.U[l - 1][changes, :], self.W[l]) # Update the preactivation values 
                self.U[l][changes, :] = act(self.S[l][changes, :]) # Update the activation values
                l += 1 # Move one layer forward 
            self.S[l][changes, :] = torch.mm(self.U[l - 1][changes, :], self.W[l]) # Update the preactivation values
            self.O[changes] = o.calculate_objective(self.S[l][changes, :], self.batch.Y[changes]) # Update the objectives 

    def perturb(self, ps):
        for _ in range(ps):
            if self.weights_search is None:
                w = random.choice(self.weights)
            else:
                w = random.choice(self.weights_search)
            u, l, v = w.u, w.l, w.v 
            current_value = self.W[l][u, v] 
            if self.settings.network_type == 'TNN':
                new_values = [-1, 0, 1] 
                new_values.remove(current_value)
                new_value = random.sample(new_values, 1)[0]
            elif self.settings.network_type == 'BNN':
                new_value = -1 * current_value
            delta_w = new_value - current_value 
            self.commit_move(Move(w, 0, delta_w))

    # Function to select weights that should be part of the search in sporadic local search. p must either be a a single float or a list of floats (one for each layer)
    def select_search_weights(self, bp):
        self.weights_search = []
        if isinstance(bp, list):
            for l in self.W_search:
                self.W_search[l] = torch.bernoulli(torch.full(self.W_search[l].shape, bp[l-1]))
                self.weights_search.extend([Weight(u, l, v) for u, v in torch.nonzero(self.W_search[l])])
        else:
            if bp == 1:
                self.W_search = {l: torch.ones(self.settings.network_structure[l-1], self.settings.network_structure[l], dtype = torch.int32) for l in range(1, self.settings.L + 1)}
                self.weights_search = [Weight(u, l, v) for l in range(1, self.settings.L + 1) for v in range(self.settings.network_structure[l]) for u in range(self.settings.network_structure[l-1])]
            else:
                for l in self.W_search:
                    self.W_search[l] = torch.bernoulli(torch.full(self.W_search[l].shape, bp))
                    self.weights_search.extend([Weight(u, l, v) for u, v in torch.nonzero(self.W_search[l])])

    # Function that replaces the batch attached to the solution and re-evaluates it. 
    def change_batch(self, batch):
        self.batch = batch 
        self.U[0] = self.batch.X 
        self.evaluate()
        if self.settings.logging == True:
            self.logging['moves_per_batch'].append(0)