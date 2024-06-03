rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="MBT"
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
    Algorithm = temp$settings$algorithm
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, NetworkStructure, Algorithm) %>%
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

double_layer_wide <- double_layer %>%
  select(-SD, -Layers) %>%
  pivot_wider(names_from = NetworkStructure, values_from = Mean, values_fill = NA) %>%
  mutate(NetworkStructure = "Two")

final_table <- bind_rows(single_layer_wide, double_layer_wide)

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("softmax", "max probability", ObjectiveFunction))

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training_ils", "Iterated Local Search", Algorithm))

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training_fine_tuning", "Aggregation Algorithm", Algorithm))

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training", "Iterated Improvement", Algorithm))

# Combine single and double layer data
final_table <- final_table %>%
  mutate(`16` = coalesce(`16`, `16-16`),
         `128` = coalesce(`128`, `128-128`)) %>%
  select(ObjectiveFunction, NetworkStructure, Algorithm, `16`, `128`)

final_table <- final_table %>%
  rename(
    `Objective function` = ObjectiveFunction,
    `Hidden layers` = NetworkStructure
  )

align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on MNIST for different network structures and algorithms. The network is a
            BNN trained with a time limit of 600 seconds. Iterated Improvement and Iterated Local Search refers to
            Algorithm 4, and here early stopping is used. The validation set consists of 12,000 samples and for
            II, the validation accuracy is calculated every fourth batch, whereas for ILS, it is calculated after every batch.
            The solution with the highest validation accuracy is returned. I set bp equal to 0.2 and ps to 25.
            Each ILS phase is allowed to run for 5 seconds. 
            For the Aggregation Algorithm, I do not use early stopping, but instead return the solution at the end. The parameters
            updateStart, updateEnd and updateIncrease are set to 1, 15 and 10 respectively. For all the algorithms,
            a batch size of 1000 is used.}}"

final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT", digits = c(4))


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

#latex_code <- gsub("\\\\begin\\{table\\}\\[!tb\\]", "\\\\begin\\{table\\}\\[!tb\\]\\\\resizebox\\{\\\\textwidth\\}\\{!\\}\\{", latex_code)

#latex_code <- gsub("\\\\end\\{tabular\\}", "\\\\end\\{tabular\\} \\}", latex_code)

#latex_code
write(latex_code, file = output_file)

