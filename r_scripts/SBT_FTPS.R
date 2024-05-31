rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/SBT_FTPS")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    NeuronsHiddenLayer = paste(temp$settings$network_structure[-c(1, length(temp$settings$network_structure))], collapse = "-"),
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas,
    PerturbationSize = temp$settings$perturbation_size
  ))
}

summary_stats <- results %>%
  group_by(NeuronsHiddenLayer, PerturbationSize) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

final_table <- summary_stats

final_table$NeuronsHiddenLayer <- factor(final_table$NeuronsHiddenLayer, 
                                         levels = c("16", "128"))

final_table <- final_table %>%
  arrange(NeuronsHiddenLayer, PerturbationSize, desc = FALSE)
# Print the final table
print(final_table)


align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "The mean test accuracies on MNIST for two different networks with a single hidden layer.
            The results are obtained by training a BNN on a single batch with 2000 samples using the ILS
            algorithm with a time limit of 300 seconds. "

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "SBT_FTPS", digits = c(4))

# Specify the file path
output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/SBT_FTPS.tex"

# Write to LaTeX file using xtable
print(final_xtable, file = output_file, type = "latex", include.rownames = FALSE)


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/SBT_FTPS.tex")

