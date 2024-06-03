rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="MBT_FTBP"
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
    NeuronsHiddenLayer = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    BP = temp$settings$bernoulli_parameter,
    Algorithm = temp$settings$algorithm
  ))
}

summary_stats <- results %>%
  group_by(Algorithm, BP) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

final_table <- summary_stats

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training_ils", "Iterated Local Search", Algorithm))

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training_fine_tuning", "Aggregation Algorithm", Algorithm))

final_table <- final_table %>%
  mutate(Algorithm = gsub("batch_training", "Iterated Improvement", Algorithm))


align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on MNIST for three different algorithms with different values of bp.
            The results are obtained by training a BNN for a time limit of 600 seconds. For II, k=4, for
            ILS, k=1 and each ILS phase runs for 5 seconds with a perturbation size of 25. For AA updateStart, updateEnd
            and updateIncrease are 1, 15 and 10 respectively.}}"

final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT_FTBP", digits = c(0,0,1,4,4))



latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

write(latex_code, file = output_file)

