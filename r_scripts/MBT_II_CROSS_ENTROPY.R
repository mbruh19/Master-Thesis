
rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/MBT")
files <- list.files()

results <- data.frame()

objective_function = "cross_entropy"

train_accuracies <- numeric(50)
val_accuracies <- numeric(50)
count <- numeric(50)


for (file in files) {
  temp = fromJSON(file)
  if (temp$settings$algorithm == 'batch_training' && temp$settings$objective_type == objective_function &&
      all(temp$settings$network_structure == c(784, 128, 128, 10))) {
    
    for (i in seq_along(temp$val_accuracies)){
      val_accuracies[i] <- val_accuracies[i] + temp$val_accuracies[i]
      train_accuracies[i] <- train_accuracies[i] + temp$train_accuracies[i]
      count[i] <- count[i] + 1
    }
    results <- rbind(results, data.frame(
      Seed = temp$settings$seed, 
      ObjectiveFunction = temp$settings$objective_type,
      NetworkStructure = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
      Accuracy = temp$Test_accuracy,
      Algorithm = temp$settings$algorithm,
      Batches = length(temp$iterated_improvement_moves),
      MovesPerBatch = mean(temp$iterated_improvement_moves),
      MovesFirst30Batches = mean(temp$iterated_improvement_moves[1:30])))
  }
}

val_accuracies <- val_accuracies / count 
train_accuracies <- train_accuracies/count

highest_index <- max(which(!is.nan(train_accuracies))) - 1

df <- data.frame(
  Batch = 1:length(train_accuracies[1:highest_index])*4,
  TrainAccuracy = train_accuracies[1:highest_index],
  ValAccuracy = val_accuracies[1:highest_index]
)

df_long <- tidyr::pivot_longer(df, cols = c("TrainAccuracy", "ValAccuracy"),
                               names_to = "Type", values_to = "Accuracy")

p <- ggplot(df_long, aes(x = Batch, y = Accuracy, color = Type, group = Type)) +
  geom_line() +
  geom_point() +
  labs(title = "Training and Validation Accuracies for the Cross-Entropy Objective Function",
       x = "Batches",
       y = "Accuracy") +
  scale_x_continuous(breaks = seq(0, length(train_accuracies)*4, 10)) +
  scale_y_continuous(breaks = seq(0, 1, 0.1)) +
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = "white", colour = "black"))

# Print the plot
print(p)



ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/MBT_II_CROSS_ENTROPY.png", plot = p, dpi = 300, bg = "white")


