rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BatchTrainingILS")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    Accuracy = temp$Test_accuracy,
    Runtime = temp$`Total runtime`,
    BestValAccuracy = which.max(temp$val_accuracies) - 1
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanRuntime = mean(Runtime),
    SDRuntime = sd(Runtime),
    BestValAccuracy = mean(BestValAccuracy),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 2, nsmall = 2),
         SDRuntime = format(SDRuntime, digits = 4, nsmall = 4),
         Mean = format(Mean, digits = 4, nsmall = 4),
         ObjectiveFunction = gsub("_", "-", ObjectiveFunction))

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunction = gsub("softmax", "max probability", ObjectiveFunction))

align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "Summary statistics for the Multiple Batches Iterated Local Search algorithm.
A BNN is trained with a single hidden layer with
64 neurons. The batch size is 1000, and the BestValAccuracy column tells on average how many validation
accuracies were calculated before the best one was found."
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "BatchTrainingILS")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/BatchTrainingILS.tex"

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)




