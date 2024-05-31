rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/exp1")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  objective_function <- temp$settings$objective_type 
  if(objective_function == "pairwise"){
    pos = nchar(file) - 5 
    objective_function = paste0(objective_function,substr(file, pos, pos))
  }
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = objective_function,
    BatchSize = temp$settings$batch_size, 
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, BatchSize) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = BatchSize, y = Mean, group = ObjectiveFunction, color = ObjectiveFunction)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = ObjectiveFunction), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Accuracy for Different Objective Functions for a Single Batch",
       x = "Batch size",
       y = "Accuracy") +
  scale_x_continuous(breaks = seq(100, 1000, 100))+  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0.1, 0.7, 0.1)) + 
  coord_cartesian(xlim = c(90, 1010), ylim = c(0.05, 0.75)) + 
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/SBT_COF.png", plot = p, dpi = 300, bg = "white")

