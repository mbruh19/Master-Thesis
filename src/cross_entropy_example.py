import torch
import torch.nn as nn
import torch.nn.functional as F
import math 



pre_activation = torch.tensor([[4.0, 2.0, -2.0, -2.0, -2.0]])
label = torch.tensor([0])

probabilities = F.softmax(pre_activation, dim=1)
print("Probabilities after softmax:")
print(probabilities)

print("The cross-entropy loss manually", -math.log(probabilities[0][label[0]]))
criterion = nn.CrossEntropyLoss()
loss = criterion(pre_activation, label)

print("Cross Entropy Loss by Torch function:", loss.item())

pre_activation = torch.tensor([[4.0, 2.0, -4.0, -2.0, -2.0]])
label = torch.tensor([0])

probabilities = F.softmax(pre_activation, dim=1)
print("Probabilities after softmax:")
print(probabilities)

print("The cross-entropy loss manually", -math.log(probabilities[0][label[0]]))
criterion = nn.CrossEntropyLoss()
loss = criterion(pre_activation, label)

print("Cross Entropy Loss by Torch function:", loss.item())



pre_activation = torch.tensor([-2.0])

label = torch.tensor([1.0])

criterion = nn.BCEWithLogitsLoss()
loss = criterion(pre_activation, label)

probability = 1 / (1 + math.exp(- pre_activation[0]))

print("probability", probability)

print("Binary Cross Entropy Loss manually", - label[0] * math.log(probability) - (1 - label[0]) * math.log(1 - probability))
print("Binary Cross Entropy Loss by Torch function", loss.item())