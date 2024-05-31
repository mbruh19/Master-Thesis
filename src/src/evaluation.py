import torch
from torch.utils.data import DataLoader

from .utils import act 
from .utils import forward 
from .utils import neural_network_evaluator

import sys

class Evaluation():
    def __init__(self, instance):
        self.instance = instance 
    
    def training_accuracy(self, batch, S, misclassified = False):
        if self.instance.settings.classification_type == 'binary':
            return self.binary_accuracy(batch, S)
        elif self.instance.settings.classification_type =='multi':
            return self.multiclass_accuracy(batch, S, misclassified)

    def binary_accuracy(self, batch, S):
        Y = batch.Y.unsqueeze(1)
        predictions = torch.where(S >= 0, 1, 0)
        result = (predictions == Y)
        total_correct = result.sum().item()
        
        # print(f"Training accuracy {total_correct/ Y.shape[0]}")
        return total_correct / len(Y)
    
    def multiclass_accuracy(self, batch, S, misclassified = False):
        Y = batch.Y
        
        predictions = torch.argmax(S, dim = 1)
        result = (predictions == Y)
        total_correct = result.sum().item()
        if misclassified:
            misclassified_counts = {}
            for label, prediction, correct in zip (Y, predictions, result):
                if not correct.item():
                    if label.item() not in misclassified_counts:
                        misclassified_counts[label.item()] = 0
                    misclassified_counts[label.item()] += 1
            print(f"The training accuracy is {total_correct/ len(Y)}")

            print("Misclassified counts per label:", misclassified_counts)

        
        # print(f"Training accuracy {total_correct/ len(Y)}")
        return total_correct / len(Y)
    
    def test_accuracy(self, dataset, batch_size, weights, misclassified = False):
        if dataset == "validation":
            loader = DataLoader(self.instance.val_dataset, batch_size = batch_size, shuffle = True)
        elif dataset == "test":
            loader = DataLoader(self.instance.test_dataset, batch_size = batch_size, shuffle = True)
        else:
            raise ValueError(f"dataset argument must be either 'validation' or 'test'. Got {dataset}")
        batch = next(iter(loader))
        Y = batch[1]
        U = batch[0].view(len(Y), -1)
        l = 1 
        while l < len(weights):
            S = forward(U, weights[l])
            U = act(S)
            l += 1 
        S = forward(U, weights[l])

        predictions = torch.argmax(S, dim = 1)
        result = (predictions == Y)
        total_correct = result.sum().item()

        if misclassified:
            misclassified_counts = {}
            for label, prediction, correct in zip (Y, predictions, result):
                if not correct.item():
                    if label.item() not in misclassified_counts:
                        misclassified_counts[label.item()] = 0
                    misclassified_counts[label.item()] += 1
                
            print(f"The {dataset} accuracy is {total_correct/ len(Y)}")

            print("Misclassified counts per label:", misclassified_counts)

        # print(f"{dataset} accuracy {total_correct/ len(Y)}")
        return total_correct / len(Y)

    
    def binary_test_accuracy(self, weights):
        loader = self.instance.loader("test", self.instance.settings.test_batch_size)
        batch = next(loader)

        count_status = [0, 0, 0, 0, 0, 0, 0]

        my_label = []
        right_label = []

        for k in range(batch.get_ninstances()):
            x = batch.X[k, :]
            y = batch.Y[k].item()
            right_label.append(y)
            tentative = {}

            for q in weights:
                (i, j) = q 
                w = neural_network_evaluator(x, weights[q], [i, j])
                # print(f"{i,j} propose {w} and the correct is {y}")
                tentative[q] = w 
            
            label_nets = {} # Dictionary with labels as keys. For each key a list of the networks that voted for that label is stored. 
            for d in range(10):
                vec = []
                for q in tentative.keys():
                    if tentative[q] == d: 
                        vec.append(q)
                label_nets[d] = vec 
            label_nets_len = {k: len(v) for k, v in label_nets.items()}
            # H = open("results_{}/labels_{}_{}.csv".format(1, 2, 1), "a")
            info2 = [y] + [label_nets_len[i] for i in range(10)]

            '''voting scheme and label statuses'''
            sort_label = {k: v for k, v in sorted(label_nets_len.items(), key=lambda item: item[1], reverse=True)}
            if label_nets_len[list(sort_label.keys())[0]] >= label_nets_len[list(sort_label.keys())[1]] + 1:
                this_label = list(sort_label.keys())[0]
                my_label.append(this_label)
                info2.append(this_label)
                if this_label == y:
                    status = 0
                    count_status[0] += 1
                else:
                    status = 6
                    count_status[6] += 1
            elif label_nets_len[list(sort_label.keys())[0]] == label_nets_len[list(sort_label.keys())[1]] and \
                    label_nets_len[list(sort_label.keys())[1]] >= label_nets_len[list(sort_label.keys())[2]] + 1:
                if list(sort_label.keys())[0] < list(sort_label.keys())[1]:
                    this_label = tentative[(list(sort_label.keys())[0], list(sort_label.keys())[1])]
                else:
                    this_label = tentative[(list(sort_label.keys())[1], list(sort_label.keys())[0])]
                my_label.append(this_label)
                info2.append(this_label)
                if this_label == y:
                    status = 1
                    count_status[1] += 1
                elif this_label != y and (y == list(sort_label.keys())[0] or y == list(sort_label.keys())[1]):
                    status = 2
                    count_status[2] += 1
                else:
                    status = 5
                    count_status[5] += 1
            else:
                my_label.append(-1)
                info2.append(-1)
                if label_nets_len[y] == label_nets_len[list(sort_label.keys())[0]]:
                    status = 3
                    count_status[3] += 1
                else:
                    status = 4
                    count_status[4] += 1
            info2.append(status)

            '''
            labels_i_j.csv
            
            info2 = right label / how many networks labelled it as a 0 / how many as a 1 / ... / how many as a 9 / 
                    label given / status
            status :    0 = there was one maximum value and the label was correct
                        1 = there were two maximum values and the label was correct
                        2 = there were two maximum values, the label was not the one given but the other one
                        3 = there were more than three maximum value and one of these was correct
                        4 = there were more than three maximum values, all wrong
                        5 = there were two maximum values, both wrong
                        6 = there was one maximum value and the label was wrong       
            '''

            # H.write(",".join([str(x) for x in info2]))
            # H.write("\n")
            # H.close()

        print(count_status)
        # counting how many correct
        count = 0
        # counting how many not classified
        count1 = 0
        for h in range(len(my_label)):
            if int(my_label[h]) == right_label[h]:
                count += 1
            elif int(my_label[h]) == -1:
                count1 += 1
        print("The testing accuracy is", count / len(my_label))
        return count/len(my_label)
        