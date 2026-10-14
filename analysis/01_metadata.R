library(readr)
library(dplyr)
library(stringr)
library(here)

sra <- read_csv(here("data","metadata","SraRunTable.csv"), show_col_types = FALSE)

sra <- select(sra, Run, sample_name = "Sample Name")

sra <- mutate(sra, sample_type = case_when(
  str_detect(sample_name, "Neg") ~ "negative_control",
  str_detect(sample_name, "MCC") ~ "mock",
  .default = "subject"
))

count(sra, sample_type)
stopifnot(
  nrow(sra) == 56,
  sum(sra$sample_type == "subject") == 48,
  sum(sra$sample_type == "negative_control") == 6,
  sum(sra$sample_type == "mock") == 2
)
