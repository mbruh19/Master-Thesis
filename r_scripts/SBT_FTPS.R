rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="SBT_FTPS"
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




align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on MNIST for two different networks with a single hidden layer.
            The results are obtained by training a BNN on a single batch with 2000 samples using the ILS
            algorithm with a time limit of 300 seconds.}}"

final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "SBT_FTPS", digits = c(4))

latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

write(latex_code, file = output_file)

