
rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/MBT")
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
# Printing the final table
print(final_table)



final_table <- final_table %>%
  rename(
    `Objective function` = ObjectiveFunction,
    `Hidden layers` = NetworkStructure
  )

align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "Summary statistics for the Iterated Improvement version of Algorithm 4. 'MeanMoves is the average number of moves made per batch
            and MeanMoves30 is the average number of moves made per batch in the first 30 batches. "

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT_II", digits = c(0,0,0, 4, 2, 4, 4))

# Specify the file path
output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_II.tex"

# Write to LaTeX file using xtable
print(final_xtable, file = output_file, type = "latex", include.rownames = FALSE)


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_II.tex")

