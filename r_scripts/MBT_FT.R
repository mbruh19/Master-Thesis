rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/MBT_FT_II")
files <- list.files()
results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    NetworkStructure = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    Algorithm = "Iterated Improvement",
    BP = temp$settings$bernoulli_parameter,
    Runtime = temp$`Total runtime`
  ))
}

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/MBT_FT_ILS")
files <- list.files()
for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    NetworkStructure = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    Algorithm = "Iterated Local Search",
    BP = temp$settings$bernoulli_parameter,
    Runtime = temp$`Total runtime`
  ))
}



summary_stats <- results %>%
  group_by(Algorithm, NetworkStructure, BP) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanRuntime = mean(Runtime),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 2, nsmall = 0, scientific = FALSE),
         Mean = format(Mean, digits = 4, nsmall = 4),
         MeanRuntime = format(MeanRuntime, digits = 2))

final_table <- summary_stats

# Print the final table
print(final_table)
align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "The mean test accuracies for the two versions of the Multiple Batch Training algorithm.
            The batch size is 1000. The iterated improvement version is allowed to run for 10 epochs.
            The iterated local search runs for 2 epochs, where each ILS phase has a time limit of 8 seconds.
            The perturbation size is set to 25. The interval to calculate validation accuracies are 20 (II)
            and 4 (ILS)."

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "MBT_FT", digits = c(0,0,0, 2, 4, 4, 0))

# Specify the file path
output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_FT.tex"

# Write to LaTeX file using xtable
print(final_xtable, file = output_file, type = "latex", include.rownames = FALSE)


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/MBT_FT.tex")
