import torchvision.transforms as transforms
from torchvision.datasets import MNIST, FashionMNIST, CIFAR10
from adult import Adult
from torch.utils.data import random_split, Subset
import torch
from collections import defaultdict

import sys

class Reader:
    def __init__(self, settings):
        self.settings = settings
        self.dataset = settings.dataset
        self.validation_percentage = settings.validation_percentage
        self.batch_size = settings.batch_size

    def load_data(self):
        if self.dataset == "MNIST":
            dataset = MNIST
        elif self.dataset == "FMNIST":
            dataset = FashionMNIST
        elif self.dataset == "CIFAR10":
            dataset = CIFAR10
        elif self.dataset == "Adult":
            return self.load_adult()
        else:
            raise ValueError(f"Unsupported dataset: {self.dataset}")

        # For MNIST and FMNIST the input are converted back to its original integer values.
        transform = transforms.Compose([
            transforms.ToTensor(),
            lambda x: x * 255,
            lambda x: x.to(dtype = torch.int32)])
        train_dataset = dataset(root = "../data", train = True, transform = transform, download = True)
        test_dataset = dataset(root='../data', train=False, transform= transform, download=True)

        targets = list(set(train_dataset.targets.tolist()))
        
        train_size = int((1 - self.validation_percentage) * len(train_dataset)) 
        val_size = len(train_dataset) - train_size
        train_set, val_set = random_split(train_dataset, [train_size, val_size])


        if self.settings.sample_type == "balanced":
            train_set = Subset(train_set, self.get_balanced_indices(targets, train_set, self.settings.batch_size))
            val_set = Subset(val_set, self.get_balanced_indices(targets, val_set, self.settings.validation_batch_size))
            test_dataset = Subset(test_dataset, self.get_balanced_indices(targets, test_dataset, self.settings.test_batch_size))

        return train_set, val_set, test_dataset

    def get_balanced_indices(self, targets, dataset, size):
        num_instances = int(size/len(targets))
        indices_per_class = defaultdict(list)
        counter = 0 
        while counter < size:
            for idx, sample in enumerate(dataset):
                target = sample[1]
                if len(indices_per_class[target]) < num_instances and target in targets:
                    indices_per_class[target].append(idx)
                    counter += 1
                if counter == size:
                    balanced_indices = [idx for indices in indices_per_class.values() for idx in indices]
                    return balanced_indices

    
    "Adult dataset has been converted so it has 104 input dimensions. The test dataset has 15060 samples. The training dataset has 30162 samples. "
    def load_adult(self): # Data has 104 dimensions
        train_dataset = Adult(root = "../data", train = True, download = True)
        test_dataset = Adult(root = "../data", train = False, download = True)
        
        train_size = int((1 - self.validation_percentage) * len(train_dataset)) 
        val_size = len(train_dataset) - train_size
        train_set, val_set = random_split(train_dataset, [train_size, val_size])

        return train_set, val_set, test_dataset