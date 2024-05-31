rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BNN_vs_TNN")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  objective_function <- temp$settings$objective_type 
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    NetworkType = temp$settings$network_type, 
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas,
    TimeLimit = temp$settings$time_limit
  ))
}

summary_stats <- results %>%
  group_by(NetworkType, TimeLimit) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanLocalOptimas = mean(LocalOptimas),
    .groups = 'drop'
  )

# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = TimeLimit, y = Mean, group = NetworkType, color = NetworkType)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = NetworkType), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Comparison of BNN vs TNN",
       x = "Time Limit in Seconds",
       y = "Test Accuracy") +
  scale_x_continuous(breaks = seq(30, 390, 30))+  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0.64, 0.80, 0.02)) + 
  coord_cartesian(xlim = c(25, 400), ylim = c(0.64, 0.80)) + 
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = "white", colour = "black"))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/BNN_vs_TNN.png", plot = p, dpi = 300, bg = "white")

