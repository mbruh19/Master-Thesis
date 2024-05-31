rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/SBT_TETL")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    TimeLimit = temp$settings$time_limit, 
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas,
    AverageMoves = mean(temp$iterated_improvement_moves)
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, TimeLimit) %>%
  summarise(
    Mean = mean(LocalOptimas),
    SD = sd(LocalOptimas),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunction = gsub("softmax", "max probability", ObjectiveFunction))

# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = TimeLimit, y = Mean, group = ObjectiveFunction, color = ObjectiveFunction)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = ObjectiveFunction), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Average Number of Local Optimas Reached for the ILS Algorithm",
       x = "Time Limit in Seconds",
       y = "Local Optimas") +
  scale_x_continuous(breaks = seq(10, 100, 10)) +  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0, 500, 50)) +
  coord_cartesian(xlim = c(10, 101), ylim = c(-1, 500))+
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = "white", colour = "black"))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/SBT_TETL_LOCAL_OPTIMAS.png", plot = p, dpi = 300, bg = "white")


