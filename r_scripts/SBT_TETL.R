rm(list=ls())
library(jsonlite)
library(dplyr)
library(tidyr)
library(xtable)
library(ggplot2)
library(rstudioapi)

file ="SBT_TETL"
log_path <-dirname(rstudioapi::getActiveDocumentContext()$path)
log_path <- file.path(log_path, "../log")
log_path <- file.path(log_path, file)
setwd(log_path)

output_file <- paste(file.path(dirname(rstudioapi::getActiveDocumentContext()$path), "../tex/Thesis/Tables", file), ".tex", sep="")

files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  objective_function <- temp$settings$objective_type 
  if(objective_function == "pairwise"){
    pos = nchar(file) - 5 
    objective_function = paste0(objective_function,substr(file, pos, pos))
  }
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjectiveFunction = objective_function,
    BatchSize = temp$settings$batch_size/10, 
    Accuracy = temp$Test_accuracy,
    LocalOptimas = temp$local_optimas,
    TimeLimit = temp$settings$time_limit
  ))
}

summary_stats <- results %>%
  group_by(ObjectiveFunction, TimeLimit) %>%
  summarise(
    Mean = mean(Accuracy),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(ObjectiveFunction = gsub("_", "-", ObjectiveFunction))



summary_stats

final_table <- summary_stats %>%
  pivot_wider(
    names_from = TimeLimit,
    values_from = Mean,
    names_prefix = "TL: "
  )



align_string <- paste("|", paste(rep("c", ncol(final_table) + 1), collapse = "|"), "|", sep="")

caption <- "\\small{\\textbf{The mean test accuracies on MNIST for different time limits. The results are obtained by training a 
            BNN on a single batch with 200 samples for each digit. The algorithm used is the ILS algorithm
            with the perturbation size set to 25. The time limit is in seconds.}}"

# Convert to xtable
final_xtable <- xtable(final_table, align = align_string, caption = caption, label = "SBT_TETL", digits = c(4))


latex_code <- print(final_xtable, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(final_table))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)

