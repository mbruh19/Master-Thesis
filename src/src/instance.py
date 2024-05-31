from torch.utils.data import DataLoader
from . import reader 
import torch

import sys 

class Batch:
    def __init__(self, data, labels):
        if data.shape[1] == 1:
            self.X = data.view(len(labels), -1)
        else:
            self.X = data 
        self.Y = labels
        self.max_value = torch.max(self.X).item()


    def get_ninstances(self):
        return len(self.Y)


class Instance:
    def __init__(self, settings, train_dataset, val_dataset, test_dataset):
        self.settings = settings
        self.train_dataset = train_dataset
        self.val_dataset = val_dataset
        self.test_dataset = test_dataset

    def loader(self, dataset, batch_size, shuffle = True):
        if dataset not in ["train", "val", "test"]:
            raise ValueError(f"'dataset' must be one of 'train', 'val', or 'test'. Got: {dataset}")

        if dataset == "train":
            ds = self.train_dataset
        elif dataset == "val":
            ds = self.val_dataset
        elif dataset == "test":
            ds = self.test_dataset
        
        data_loader = DataLoader(ds, batch_size, shuffle = shuffle, drop_last = True)

        for data, labels in data_loader:
            yield Batch(data, labels)

    def n_labels(self):
        data_loader = DataLoader(self.test_dataset, len(self.test_dataset), shuffle = False, drop_last = True)
        for data, labels in data_loader:
            return len(set(labels.tolist()))
