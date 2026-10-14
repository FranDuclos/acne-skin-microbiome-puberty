library(readr)
library(dplyr)
library(stringr)
library(here)
library(tidyr)

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

subjects <- filter(sra, sample_type == "subject")

subjects <- separate_wider_delim(
  subjects, sample_name,
  delim = "_",
  names = c("subject_id", "tanner_stage", "status_acne"),
  cols_remove = FALSE)

subjects <-  mutate(subjects, subject_id = as.integer(subject_id))

stopifnot(
  nrow(subjects) == 48,
  !anyNA(subjects$subject_id),
  n_distinct(subjects$subject_id) == 48,
  all(subjects$status_acne %in% c("Acne", "Normal")),
  all(subjects$tanner_stage %in% c("T1", "T2", "T3", "T4", "T5"))
)


