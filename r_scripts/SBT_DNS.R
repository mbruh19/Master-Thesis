rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="SBT_DNS"
log_path <-dirname(rstudioapi::getActiveDocumentContext()$path)
log_path <- file.path(log_path, "../log")
log_path <- file.path(log_path, file)
setwd(log_path)

output_file <- paste(file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "../tex/Thesis/Tables", file), ".tex", sep="")

files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    NetworkStructure = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, NetworkStructure) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

# Function to extract number of layers
extract_layers <- function(network_structure) {
  length(strsplit(network_structure, "-")[[1]])
}

summary_stats <- summary_stats %>% 
  mutate(Layers = sapply(NetworkStructure, extract_layers))

single_layer <- summary_stats %>% filter(Layers == 1)
double_layer <- summary_stats %>% filter(Layers == 2)

single_layer_wide <- single_layer %>%
  select(-SD, -Layers) %>%
  pivot_wider(names_from = NetworkStructure, values_from = Mean, values_fill = NA) %>%
  mutate(NetworkStructure = "One")

# Pivoting the double layer data
double_layer_wide <- double_layer %>%
  select(-SD, -Layers) %>%
  pivot_wider(names_from = NetworkStructure, values_from = Mean, values_fill = NA) %>%
  mutate(NetworkStructure = "Two")

# Combining the tables
final_table <- bind_rows(single_layer_wide, double_layer_wide)

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("softmax", "max probability", ObjectiveFunction))

# Printing the final table
print(final_table)

# Combine single and double layer data
final_table <- final_table %>%
  mutate(`16` = coalesce(`16`, `16-16`),
         `128` = coalesce(`128`, `128-128`)) %>%
  select(ObjectiveFunction, NetworkStructure, `16`, `128`)

final_table <- final_table %>%
  rename(
    `Objective function` = ObjectiveFunction,
    `Hidden layers` = NetworkStructure
  )

# Print the final table
print(final_table)
align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on MNIST for different network structures. The results are obtained by training a BNN
            on a single batch with 2000 samples using the ILS algorithm with a time limit of 300 seconds.
            The columns indicate the width of the hidden layers.}}"

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "SBT_DNS", digits = c(4))


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)

