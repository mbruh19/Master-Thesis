rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BEMI_BS")
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
    ImagesPerDigit = temp$settings$batch_size/10, 
    Accuracy = temp$Test_accuracy
  ))
}

summary_stats <- results %>%
  group_by(ImagesPerDigit) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = ImagesPerDigit, y = Mean)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Test Accuracy for the BeMi Ensemble on MNIST",
       x = "Training Images per Digit",
       y = "Test Accuracy") +
  scale_x_continuous(breaks = seq(10, 150, 10))+  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0.5, 0.9, 0.05)) + 
  coord_cartesian(xlim = c(9, 151), ylim = c(0.5, 0.95)) + 
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/BEMI_BS.png", plot = p, dpi = 300, bg = "white")

