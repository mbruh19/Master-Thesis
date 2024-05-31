import torch

from ..solution import Solution 
from ..solvers.solvers import * 
from ..evaluation import Evaluation
from ..instance import Batch

def binary_training(instance, settings, train_data):
    weights = {}
    connections = []
    e = Evaluation(instance)
    for i in range(instance.n_labels()):
        for j in range(i + 1, instance.n_labels()):
            data = torch.cat((train_data[i].X, train_data[j].X), dim = 0)
            labels = torch.cat((train_data[i].Y, train_data[j].Y), dim = 0)
            labels = torch.where(labels == i, 1, 0)
            batch = Batch(data, labels)

            s = Solution(batch, settings)
            s.random_solution()
            s = ils(s, settings.single_model_time_limit, settings.perturbation_size)

            if settings.logging == True:
                s.logging['connections_per_classifier'].append(s.n_connections)
            print(e.training_accuracy(s.batch, s.S[s.settings.L]), s.n_connections, s.obj_value(True))
            # print(f"({i, j}) {s.obj_value()}")
            
            weights[(i, j)] = s.copy_weights()
            connections.append(s.n_connections)
    return weights, s, connections