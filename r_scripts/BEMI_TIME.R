rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="BEMI_TIME"
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
    Accuracy = temp$Test_accuracy,
    TrainingTime = temp$settings$single_model_time_limit * 45
  ))
}

summary_stats <- results %>%
  group_by(TrainingTime) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 4, nsmall = 2),
         Mean = format(Mean, digits = 4, nsmall = 4))



align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "\\small{\\textbf{Summary statistics for the BeMi ensemble on MNIST for different time limits. The
          network is a BNN with a single hidden layer with 10 neurons and the training is based on
          100 images per digit. I use cross-entropy as objective function.}}"
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "BEMI_TIME")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)




