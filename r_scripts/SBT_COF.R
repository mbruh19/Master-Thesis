rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/SBT_COF")
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
    BatchSize = temp$settings$batch_size/10, 
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

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))


# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = BatchSize, y = Mean, group = ObjectiveFunction, color = ObjectiveFunction)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = ObjectiveFunction), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Test Accuracy for Different Objective Functions for a Single Batch",
       x = "Training Samples per Digit",
       y = "Test Accuracy") +
  scale_x_continuous(breaks = seq(10, 200, 10))+  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0.45, 0.75, 0.05)) + 
  coord_cartesian(xlim = c(9, 210), ylim = c(0.45, 0.75)) + 
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = "white", colour = "black"))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/SBT_COF.png", plot = p, dpi = 300, bg = "white")

