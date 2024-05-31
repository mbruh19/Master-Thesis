rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/TNN_REG_TL_90")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = temp$settings$objective_type,
    Reg = temp$settings$reqularization_parameter,
    Accuracy = temp$Test_accuracy,
    ActiveConnections = temp$Active_connections,
    LocalOptimas = temp$local_optimas
  ))
}

summary_stats <- results %>%
  group_by(Reg) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    MeanConnections = mean(ActiveConnections),
    SDConnections = sd(ActiveConnections),
    MeanLocalOptimas = mean(LocalOptimas),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 2, nsmall = 2),
         Mean = format(Mean, digits = 4, nsmall = 4),
         MeanConnections = format(MeanConnections, digits = 2),
         MeanLocalOptimas = format(MeanLocalOptimas, digits = 2),
         SDConnections = format(SDConnections, digits = 2),
         Reg = format(as.numeric(Reg), scientific = FALSE))



align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")


caption = "Summary statistics for single batch training of a TNN with 1000 samples. 
          The network trained has a single hidden layer with 16 neurons and is trained for
          90 seconds. "

xt <- xtable(summary_stats, align = align_string, caption = caption, label = "TNN_REG_TL_90")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/TNN_REG_TL_90.tex"

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)
