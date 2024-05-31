rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BEMI_TNN")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunc = temp$settings$objective_type,
    Reg = temp$settings$reqularization_parameter,
    PS = temp$settings$perturbation_size,
    Accuracy = temp$Test_accuracy
  ))
}

summary_stats <- results %>%
  group_by(Reg, PS) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 2, nsmall = 2),
         Mean = format(Mean, digits = 4, nsmall = 4),
         Reg = format(as.numeric(Reg), scientific = FALSE))

summary_stats <- summary_stats[order(summary_stats$Reg, summary_stats$PS), ]


align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "Summary statistics for the BeMi ensemble when trained with different perturbation sizes and 
          different regularization parameters. The random solution initialized assigns 0.1 probability to -1 and 1
          and 0.8 to 0. The networks trained has a single hidden layer with 10 neurons and is trained for
          20 seconds each, so the total training time is 900 seconds."
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "BEMI_TNN")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/BEMI_TNN.tex"

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)
