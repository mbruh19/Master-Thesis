rm(list=ls())
library(jsonlite)
library(dplyr)
library(xtable)
library(ggplot2)
library(tidyverse)

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BEMI_OBJ")
files <- list.files()

results <- data.frame()

for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjFunc = temp$settings$objective_type,
    Acc = temp$Test_accuracy,
    Images = temp$settings$batch_size,
    Time = temp$settings$single_model_time_limit * 45,
    HL = 1
  ))
}

setwd("C:/Users/Mads/OneDrive/SDU/Thesis/bnn/log/BEMI_OBJ_v2")
files <- list.files()


for (file in files) {
  temp = fromJSON(file)
  results <- rbind(results, data.frame(
    Seed = temp$settings$seed, 
    ObjFunc = temp$settings$objective_type,
    Acc = temp$Test_accuracy,
    Images = temp$settings$batch_size,
    Time = temp$settings$single_model_time_limit * 45,
    HL = 2
  ))
}


summary_stats <- results %>%
  group_by(ObjFunc, HL, Images, Time) %>%
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
  arrange(ObjFunc, Images, Time)

summary_stats <- summary_stats %>%
  pivot_wider(names_from = HL, values_from = c(Mean, SD), names_prefix = "HL_")

summary_stats <- summary_stats %>%
  rename(Mean1 = Mean_HL_1, SD1 = SD_HL_1, Mean2 = Mean_HL_2, SD2 = SD_HL_2)

summary_stats <- summary_stats %>%
  select(ObjFunc, Images, Time, Mean1, SD1, Mean2, SD2)

align_string <- paste("|", paste(rep("c", ncol(summary_stats) + 1), collapse = "|"), "|", sep="")

caption = "Mean accuracies for the BeMi ensemble. Mean1 and SD1 is for a BNN with a single hidden layer with
          10 neurons. Mean2 and SD2 is for a BNN with a hidden layer with 10 neurons followed by a hidden layer
          with 3 neurons. The training time is the total training time, so each of the 45 networks are trained for
          5 and 10 seconds respectively. The number of images, is the total number of images, so there is 10
          and 100 images for each digit respectively. "
xt <- xtable(summary_stats, align = align_string, caption = caption, label = "BEMI_OBJ", digits = c(0,0,0, 0, 2, 2, 2, 2))

latex_code <- print(xt, type = "latex", include.rownames = FALSE, floating = TRUE,
                    table.placement = "H", print.results = FALSE,
                    hline.after = c(-1, 0, seq(from = 1, to = nrow(summary_stats))), # Adding lines after each row
                    sanitize.text.function = function(x){x})

output_file <- "C:/Users/Mads/OneDrive/SDU/Thesis/bnn/tex/Thesis/Tables/BEMI_OBJ.tex"

# Wrap the LaTeX code in a center environment
latex_code <- paste("\\begin{center}", latex_code, "\\end{center}", sep="\n")

# Write the table code to a file
write(latex_code, file = output_file)




