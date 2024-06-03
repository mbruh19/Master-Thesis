rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)
library(rstudioapi)

file ="BEMI_OBJ_FMNIST"
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
    ObjFunc = temp$settings$objective_type,
    Acc = temp$Test_accuracy,
    Images = temp$settings$batch_size
  ))
}



summary_stats <- results %>%
  group_by(ObjFunc, Images) %>%
  summarise(
    Mean = mean(Acc),
    SD = sd(Acc),
    .groups = 'drop'
  )

summary_stats <- summary_stats %>%
  mutate(SD = format(SD, digits = 4, nsmall = 2),
         Mean = format(Mean, digits = 4, nsmall = 4))

summary_stats <- summary_stats %>%
  mutate(ObjFunc = gsub("_", "-", ObjFunc))
summary_stats <- summary_stats %>%
  mutate(ObjFunc = gsub("binary-", "", ObjFunc))


summary_stats <- summary_stats %>%
  arrange(ObjFunc, Images)


align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "\\small{\\textbf{Mean accuracies for the BeMi ensemble on the Fashion-MNIST dataset. The networks
          have a single hidden layer with 10 neurons and are trained for 20 seconds each, giving a total
          training time of 900 seconds. The number of images is the total number of images, so there is
          40 and 100 images for each digit respectively.}}"
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "BEMI_OBJ_FMNIST", digits = c(0,0, 2, 2, 2))

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "!tb", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)




