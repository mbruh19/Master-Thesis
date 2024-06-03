rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="TNN_COF_Adult"
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
    ObjectiveFunc = temp$settings$objective_type,
    Reg = temp$settings$reqularization_parameter,
    Accuracy = temp$Test_accuracy,
    ActiveConnections = temp$Active_connections,
    LocalOptimas = temp$local_optimas
  ))
}

summary_stats <- results %>%
  group_by(Reg, ObjectiveFunc) %>%
  summarise(
    Mean = mean(Accuracy),
    SD = sd(Accuracy),
    Connections = mean(ActiveConnections),
    LocalOptimas = mean(LocalOptimas),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 2, nsmall = 2),
         Mean = format(Mean, digits = 4, nsmall = 4),
         Connections = format(Connections, digits = 2),
         LocalOptimas = format(LocalOptimas, digits = 2),
         Reg = format(as.numeric(Reg), scientific = FALSE))

summary_stats <- summary_stats[order(summary_stats$ObjectiveFunc, summary_stats$Reg), ]

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunc = gsub("_", "-", ObjectiveFunc))

align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "\\small{\\textbf{Summary statistics for single batch training of a TNN with 800 examples from the Adult dataset. 
          The network trained has a single hidden layer with 16 neurons and is trained for
          60 seconds.}}"
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "TNN_COF_Adult")

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})


# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)
