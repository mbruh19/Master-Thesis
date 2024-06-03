rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(rstudioapi)

file ="BNN_vs_TNN_brier"
log_path <-dirname(rstudioapi::getActiveDocumentContext()$path)
log_path <- file.path(log_path, "../log")
log_path <- file.path(log_path, "BNN_vs_TNN")
setwd(log_path)

output_file <- paste(file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "../tex/Thesis/Figures", file), ".png", sep="")

files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  objective_function <- temp$settings$objective_type
  if(objective_function == "brier") {
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
  mutate(Label = gsub("BNN - brier - 0", "BNN - brier", Label))


# Plot with standard deviation as a shaded area
p <- ggplot(summary_stats, aes(x = TimeLimit, y = Mean, 
            group = Label, color = Label)) +
  geom_ribbon(aes(ymin = Mean - SD, ymax = Mean + SD, fill = Label), alpha = 0.2) +
  geom_line() +  # Connect points with lines
  geom_point() +  # Show individual data points
  labs(title = "Comparison of BNN vs TNN on MNIST with the Brier Objective Function",
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

ggsave(filename = output_file, plot = p, dpi = 300, bg = "white")

