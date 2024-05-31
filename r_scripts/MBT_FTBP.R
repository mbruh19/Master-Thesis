rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/MBT_FTBP")
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


# Print the final table
print(final_table)


align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "The mean test accuracies on MNIST for three different algorithms with different values of bp.
            The results are obtained by training a BNN for a time limit of 600 seconds. For II k=4, for
            ILS k=1 and each ILS phase runs 5 seconds and perturbation size is 25. For AA updateStart, updateEnd
            and updateIncrease are 1, 15 and 10 respectively. "

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT_FTBP", digits = c(0,0,1,4,4))

# Specify the file path
output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_FTBP.tex"

# Write to LaTeX file using xtable
print(final_xtable, file = output_file, type = "latex", include.rownames = FALSE)


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_FTBP.tex")

