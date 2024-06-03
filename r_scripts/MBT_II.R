
rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file = "MBT_II"
log_path <-dirname(rstudioapi::getActiveDocumentContext()$path)
log_path <- file.path(log_path, "../log")
log_path <- file.path(log_path, "MBT")
setwd(log_path)

output_file <- paste(file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "../tex/Thesis/Tables", file), ".tex", sep="")

files <- list.files()

results <- data.frame()


for (file in files) {
  temp = fromJSON(file)
  if (temp$settings$algorithm == 'batch_training') {
    results <- rbind(results, data.frame(
      Seed = temp$settings$seed, 
      ObjectiveFunction = temp$settings$objective_type,
      NetworkStructure = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
      Accuracy = temp$Test_accuracy,
      Algorithm = temp$settings$algorithm,
      Batches = length(temp$iterated_improvement_moves),
      MovesPerBatch = mean(temp$iterated_improvement_moves),
      MovesFirst30Batches = mean(temp$iterated_improvement_moves[1:30])))
  }
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, NetworkStructure) %>%
  summarise(
    Mean = mean(Accuracy),
    MeanBatches = mean(Batches),
    MeanMoves = mean(MovesPerBatch),
    MeanMoves30 = mean(MovesFirst30Batches),
    .groups = 'drop'
  )


final_table <- summary_stats

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))

final_table <- final_table %>%
  mutate(ObjectiveFunction = gsub("softmax", "max probability", ObjectiveFunction))

final_table$NetworkStructure <- factor(final_table$NetworkStructure, 
                                       levels = c("16", "16-16", "128", "128-128"))

final_table <- final_table %>%
  arrange(NetworkStructure)

final_table <- final_table %>%
  rename(
    `Objective function` = ObjectiveFunction,
    `Hidden layers` = NetworkStructure
  )

align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{Summary statistics for the iterated improvement version of Algorithm 4. 
            'MeanBatches' is the average number of batches seen, MeanMoves' is the average number of moves made per batch,
            and MeanMoves30 is the average number of moves made per batch in the first 30 batches.}}"

final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT_II", digits = c(0,0,0, 4, 2, 4, 4))

latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

write(latex_code, file = output_file)

