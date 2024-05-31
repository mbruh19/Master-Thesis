import torch
import math 
import sys 

class Objective_Manager:
    def __init__(self, settings):
        self.settings = settings
        self.objective_type = settings.objective_type

    def calculate_objective(self, s, y, objective_type = None):
        if objective_type == None:
            objective_type = self.objective_type
        if self.settings.classification_type == "multi":
            if objective_type == "integer":
                return self.integer_objective(s, y)
            elif objective_type =="cross_entropy":
                return self.cross_entropy_objective(s, y)
            elif objective_type == "max_probability":
                return self.softmax(s, y)
            elif objective_type == "pairwise":
                return self.pairwise_distance_objective(s, y, self.settings.p_parameter)
            elif objective_type == "brier":
                return self.brier_multi(s, y)
            else:
                raise ValueError(f' {objective_type} is not defined')
        elif self.settings.classification_type == "binary":
            if objective_type =="cross_entropy":
                return self.binary_cross_entropy_objective(s, y)
            elif objective_type =="max_probability":
                return self.binary_softmax(s,y)
            elif objective_type =="integer":
                return self.integer_binary(s, y)
            elif objective_type =="brier":
                return self.binary_brier(s, y)
            else:
                raise ValueError(f' {objective_type} is not defined')
        else:
            raise ValueError(f'An objective function is not implemented for a {self.settings.classification_type} problem')

    def integer_objective(self, s, y):
        modified_s = s.clone()
        temp = s.gather(1, y.unsqueeze(1)).squeeze()
        modified_s[torch.arange(s.size(0)), y] = -100000
        max_values = modified_s.max(dim=1).values
        losses = temp - max_values
        return losses.double()

    def cross_entropy_objective(self, s, y):
        loss = torch.nn.CrossEntropyLoss(reduction = 'none')
        return -loss(s.float(), y)

    def binary_cross_entropy_objective(self, s, y):
        s = torch.squeeze(s, 1)
        s = s.float()
        y = y.float()
        loss = torch.nn.BCEWithLogitsLoss(reduction = 'none')
        return -loss(s.float(), y)

    def pairwise_distance_objective(self, s, y, p):
        temp = torch.full(s.shape, -self.settings.network_structure[self.settings.L - 1])
        temp.scatter_(1, y.view(-1, 1), self.settings.network_structure[self.settings.L - 1])
        loss = torch.nn.PairwiseDistance(p = p)
        return - loss(s, temp)

    def softmax(self, s, y):
        s = s.float()
        m = torch.nn.Softmax(dim = 1)
        probs = m(s)
        return probs[torch.arange(s.size(0)), y]
    
    def binary_softmax(self, s, y):
        m = torch.nn.Sigmoid()
        sigmoid = m(s).squeeze()
        probabilities = torch.where(y == 0, 1 - sigmoid, sigmoid)
        return probabilities

    def integer_binary(self, s, y):
        max_value = self.settings.network_structure[self.settings.L - 1]
        s = s.squeeze()
        return torch.where(y == 0, -s + max_value, s + max_value)

    def brier_multi(self, s, y):
        s = s.float()
        m = torch.nn.Softmax(dim = 1)
        probs = m(s)
        y_true_one_hot = torch.zeros_like(probs)
        y_true_one_hot[torch.arange(s.size(0)), y] = 1 
        return -torch.sum((y_true_one_hot - probs)**2, axis = 1)

    def binary_brier(self, s, y):
        m = torch.nn.Sigmoid()
        probs = m(s).squeeze()
        return -(probs - y)**2
