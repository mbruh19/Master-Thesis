rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/exp4")
files <- list.files()

results <- data.frame()

epoch_number <- function(x) {
  return(ceiling(x / 4))
}

for (file in files) {
  temp = fromJSON(file)
  if(temp$settings$number_iterations == 40){
    EpochNumber = which.max(temp$val_accuracies) - 1
  }
  else{
    EpochNumber = epoch_number(which.max(temp$val_accuracies) - 1)
  }
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    ValFreq = temp$settings$number_iterations,
    Accuracy = temp$Test_accuracy,
    Runtime = temp$`Total runtime`,
    EpochWithBestValAcc = EpochNumber
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, ValFreq) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanRuntime = mean(Runtime),
    SDRuntime = sd(Runtime),
    BestEpoch = mean(EpochWithBestValAcc),
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

caption = "Summary statistics for the Multiple Batches Iterated Improvement algorithm.
          A BNN is trained with a single hidden layer with
          64 neurons. The batch size is 1000, and the ValFreq column indicates how often the validation accuracy
          is calculated. The BestEpoch column indicates for which epoch, on average, the best validation accuracy
          was found."
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "Early stopping")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/early_stopping.tex"

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)




