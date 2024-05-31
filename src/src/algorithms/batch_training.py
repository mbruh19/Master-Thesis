from ..solution import Solution
from ..solvers.solvers import * 
from ..evaluation import Evaluation

from time import perf_counter
import torch 

def batch_training(instance, settings, time_left):
    epochs = settings.epochs
    p = settings.bernoulli_parameter
    ps = settings.perturbation_size
    threshold = settings.threshold

    early_stopping = settings.early_stopping
    number_iterations = settings.number_iterations


    counter = 0
    
    start = perf_counter()

    loader = instance.loader('train', settings.batch_size)
    batch = next(loader)
    counter += 1 

    e = Evaluation(instance)

    s = Solution(batch, settings)

    s.random_solution()
    s.select_search_weights(p)
    s = iterated_improvement(s, time_left - (perf_counter() - start), threshold)

    if early_stopping:
        best_weights = s.copy_weights()
        best_val_accuracy = e.test_accuracy("validation", settings.validation_batch_size, s.W)
        s.logging['val_accuracies'] = [best_val_accuracy]
        s.logging['train_accuracies'] = [e.training_accuracy( s.batch, s.S[s.settings.L])]
    
    for epoch in range(epochs):
        for batch in loader:
            if perf_counter() - start < time_left:
                counter += 1 
                s.change_batch(batch)
                s.select_search_weights(p)
                # print(s.obj_value(), e.training_accuracy(s.batch, s.S[s.settings.L]), s.n_connections)
                s = iterated_improvement(s, time_left - (perf_counter() - start), threshold)
                if early_stopping and counter % number_iterations == 0:
                    val_accuracy = e.test_accuracy('validation', settings.validation_batch_size, s.W)
                    s.logging['val_accuracies'].append(val_accuracy)
                    s.logging['train_accuracies'].append(e.training_accuracy( s.batch, s.S[s.settings.L]))
                    if val_accuracy > best_val_accuracy:
                        best_val_accuracy = val_accuracy
                        best_weights = {l: torch.clone(s.W[l]) for l in s.W}
            else:
                if early_stopping:
                    s.W = best_weights
                    s.evaluate()
                    return s 
                else:
                    return s 
        loader = instance.loader('train', settings.batch_size)
    if early_stopping:
        s.W = best_weights
        s.evaluate()
        return s 
    else:
        return s 

                    