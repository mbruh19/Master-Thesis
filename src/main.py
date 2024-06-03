import argparse
import torch 
import random 
import json
from time import perf_counter
from fractions import Fraction 

from src import reader
from src import instance 
from src import evaluation 
from src.algorithms.algorithms import * 
from src.utils import get_binary_train_data

import sys 

if __name__ == '__main__':
    parser = argparse.ArgumentParser()

    parser.add_argument('-ct', '--classification_type', type = str, default = 'binary', help = 'Whether it is multiclassification or binary')

    parser.add_argument('-nt', '--network_type', type = str, default = 'TNN', help = 'Whether it is a BNN or TNN')

    parser.add_argument('-ns', '--network_structure', nargs = '+', type = int, default = [104, 16, 1], help = 'The architecture of the feedforward neural network')

    parser.add_argument('-ds', '--dataset', type = str, default = 'Adult', help = 'The dataset to solve the classification problem for.')

    parser.add_argument('-vp', '--validation_percentage', default = 0, help = 'The percentage of training set used for validation set')

    parser.add_argument('-bs', '--batch_size', type = int, default = 800, help = 'The number of samples in each batch drawn from the training set')

    parser.add_argument('-vs', '--validation_size', type = int, default = 6162, help = 'The number of samples in the validation set')

    parser.add_argument('-ts', '--test_batch_size', type = int, default = 15060, help = 'The number of samples in the test set')

    parser.add_argument('-st', '--sample_type', type = str, default = 'random', help = 'Whether to sample balanced or randomly')

    parser.add_argument('-ot', '--objective_type', type = str, default = 'integer', help = 'The type of objective function. "integer", "cross_entropy" or "brier".') 

    parser.add_argument('-p', '--p_parameter', type = int, default = 2, help = 'If objective type is pairwise, then this need to be set.')

    parser.add_argument('-al', '--algorithm', type = str, default = 'batch_training_ils', help = 'The algorithm to use')

    parser.add_argument('-so', '--solver', type = str, default = 'ils', help = 'Either "iterated_improvement", "ils" or ')

    parser.add_argument('-se', '--seed', type = int, default = 42, help = 'The seed for the experiment')

    parser.add_argument('-tl', '--time_limit', type = int, default = 60, help = 'The time limit for data loading and training, but not testing. In seconds.')

    parser.add_argument('-l', '--logging', type = bool, default = True, help = 'Whether logging is activated')

    parser.add_argument('-lf', '--logging_file', metavar = 'The directory to the logging file', type = str, default = None)

    ### ILS arguments

    parser.add_argument('-ps', '--perturbation_size', default = 30, help = 'How many variables to include in the perturbation')

    ### Iterated improvement arguments 

    parser.add_argument('-th','--threshold', type = float, default = 0, help = 'The threshold value for accepting a move')

    ### Binary experiment arguments - also used for batch training ILS

    parser.add_argument('-smtl', '--single_model_time_limit', type = float, default = 1, help = 'The time limit to train each binary classifier or each model in batch training ILS')

    ### TNN arguments

    parser.add_argument('-re','--reqularization_parameter', type = float, default = 0.5, help = 'The weight used to punish number of connections')

    ### Batch training arguments

    parser.add_argument('-ep','--epochs', type = int, default = 10, help = 'The maximum number of epochs')

    ### Sporadic local search arguments 

    parser.add_argument('-bp', '--bernoulli_parameter',nargs = '+', type = float, default = [1], help = 'The parameter to use in sporadic local search')

    ### Early stopping parameters

    parser.add_argument('-es','--early_stopping', default = False, action = 'store_true', help = 'Whether early stopping should be applied. Not possible in all algorithms')

    parser.add_argument('-ni','--number_iterations', type = int, default = 1, help = 'The number of iterations between testing on validation set')

    ### Aggregation algorithm parameters

    parser.add_argument('-us', '--update_interval_start', type = int, default = 1)

    parser.add_argument('-ue', '--update_interval_end', type = int, default = 20)

    parser.add_argument('-ui', '--update_interval_increase', type = int, default = 10)

    ### Random solution parameter

    parser.add_argument('-rsw', '--random_solution_weights', nargs = '+', type = float, default = None, help = 'The probabilities for each value when initializing the random solution')



    settings = parser.parse_args()
    print(settings.logging_file)

    settings.L = len(settings.network_structure) - 1 # Finding the index of the last layer. 

    if float(settings.perturbation_size) % 1 == 0:
        settings.perturbation_size = int(settings.perturbation_size)
    else:
        raise ValueError(f" Not yet implemented")
    
    try:
        settings.validation_percentage = float(settings.validation_percentage)
    except:
        settings.validation_percentage = float(Fraction(settings.validation_percentage))

    if len(settings.bernoulli_parameter) == 1:
        settings.bernoulli_parameter = settings.bernoulli_parameter[0]
    
    

    if settings.seed is not None:
        torch.manual_seed(settings.seed)
        random.seed(settings.seed)

    

    r = reader.Reader(settings)

    train_dataset, val_dataset, test_dataset = r.load_data()

    
    instance = instance.Instance(settings, train_dataset, val_dataset, test_dataset)

    run_delta_example = False 

    if run_delta_example:
        s = delta_example(instance, settings, settings.time_limit)
        sys.exit()

    
    if settings.classification_type == "binary":
        binary_train_data = get_binary_train_data(instance, settings)
        if settings.network_structure[settings.L] != 1:
            settings.network_structure[settings.L] = 1 
            print(f'There can only be one neuron in the last layer for binary classification. The network structure is changed to {settings.network_structure}')


    start = perf_counter()
    if settings.classification_type == 'binary':
        weights = None 
        if settings.algorithm =='binary_training':
            weights, s, connections = binary_training(instance, settings, binary_train_data)
            s.logging['connections'] = connections
        elif settings.algorithm == 'batch_training':
            s = batch_training(instance, settings, settings.time_limit - (perf_counter() - start) )
        elif settings.algorithm =='single_batch':
            s = single_batch(instance, settings, settings.time_limit - (perf_counter() - start))
        elif settings.algorithm =='aggregation_algorithm':
            s = batch_training_fine_tuning(instance, settings, settings.time_limit - (perf_counter() - start))
        elif settings.algorithm =='batch_training_ils':
            s = batch_training_ils(instance, settings, settings.time_limit - (perf_counter() - start) )
        
        if weights == None:
            weights = {}
            weights[(1, 0)] = s.copy_weights()

    elif settings.classification_type == 'multi':
        if settings.algorithm == 'single_batch': 
            s = single_batch(instance, settings, settings.time_limit - (perf_counter() - start))
        elif settings.algorithm == 'batch_training':
            s = batch_training(instance, settings, settings.time_limit - (perf_counter() - start) )
        elif settings.algorithm =='batch_training_ils':
            s = batch_training_ils(instance, settings, settings.time_limit - (perf_counter() - start) )
        elif settings.algorithm =='aggregation_algorithm':
            s = batch_training_fine_tuning(instance, settings, settings.time_limit - (perf_counter() - start))
    else:
        raise ValueError(f'There is no support to solve {settings.classification_type}. Must be either "binary" or "multi"')


    e = evaluation.Evaluation(instance)

    if settings.logging == True and settings.logging_file is not None:
        if settings.classification_type == 'binary':
            s.logging['Test_accuracy'] = e.binary_test_accuracy(weights)
            if settings.dataset == "Adult":
                s.logging['Training_accuracy'] = e.training_accuracy(s.batch, s.S[settings.L])
        else:
            e.training_accuracy(s.batch, s.S[settings.L])
            s.logging['Test_accuracy'] = e.test_accuracy("test", settings.test_batch_size, s.W)
        s.logging['Active_connections'] = s.n_connections
        s.logging['Total runtime'] = perf_counter() - start 
        with open(settings.logging_file + ".json", "w") as json_file:
            json.dump(s.logging, json_file) 
    else:
        if settings.classification_type == 'binary':
            e.binary_test_accuracy(weights)
            print(e.training_accuracy(s.batch, s.S[settings.L]))
        else:
            print("The training accuracy is", e.training_accuracy(s.batch, s.S[settings.L]))
            print("The test accuracy is", e.test_accuracy("test", settings.test_batch_size, s.W))


    print(f'The entire script took {perf_counter() - start} seconds')