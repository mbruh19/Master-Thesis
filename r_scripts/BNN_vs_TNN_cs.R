rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BNN_vs_TNN_v2")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  objective_function <- temp$settings$objective_type
  if(objective_function == "cross_entropy") {
    results <- rbind(results, data.frame(
      Seed = temp$settings$seed, 
      ObjectiveFunction = temp$settings$objective_type,
      Reg = temp$settings$reqularization_parameter,
      NetworkType = temp$settings$network_type, 
      Accuracy = temp$Test_accuracy,
      LocalOptimas = temp$local_optimas,
      TimeLimit = temp$settings$time_limit
    ))}
}

summary_stats <- results %>%
  group_by(NetworkType, TimeLimit,ObjectiveFunction, Reg) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanLocalOptimas = mean(LocalOptimas),
    .groups = 'drop'
  )

summary_stats$Label <- with(summary_stats, paste(NetworkType, ObjectiveFunction, Reg, sep = " - "))

summary_stats <- summary_stats %>%
  mutate(Label = gsub("BNN - cross_entropy - 0", "BNN - cross entropy", Label))

summary_stats <- summary_stats %>%
  mutate(Label = gsub("TNN - cross_entropy", "TNN - cross entropy", Label))



# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = TimeLimit, y = Mean, 
                               group = Label, color = Label)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = Label), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Comparison of BNN vs TNN with the Cross Entropy Objective Function",
       x = "Time Limit in Seconds",
       y = "Test Accuracy") +
  scale_x_continuous(breaks = seq(30, 300, 30))+  # Adjust x-axis breaks if necessary
  scale_y_continuous(breaks = seq(0.58, 0.78, 0.02)) + 
  coord_cartesian(xlim = c(25, 310), ylim = c(0.57, 0.78)) + 
  theme_minimal() +
  theme(legend.title = element_blank(), 
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = "white", colour = "black"))  # Adjust legend

# Print the plot
print(p)

ggsave(filename = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Figures/BNN_vs_TNN_cs.png", plot = p, dpi = 300, bg = "white")

