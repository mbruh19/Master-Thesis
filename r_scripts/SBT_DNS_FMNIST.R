rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="SBT_DNS_FMNIST"
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
    Neurons = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, Neurons) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(Neurons = as.numeric(Neurons))

summary_stats <- summary_stats %>%
  arrange(Neurons)




final_table <- summary_stats

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))
# Print the final table
print(final_table)
align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on Fashion-MNIST for different network structures. The results are obtained by training a BNN
            on a single batch with 2000 samples using the ILS algorithm with a time limit of 300 seconds.
            The network is a BNN with a single hidden layer with the number of neurons indicated by the 'Neurons' column.}}"

final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "SBT_DNS_FMNIST", digits = c(0,0,0,4,4))


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!b", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

write(latex_code, output_file)

