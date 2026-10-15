library(readr)
library(dplyr)
library(stringr)
library(here)
library(tidyr)
library(pdftools)


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

# PMC blocks d
pdf_path <- here("data", "metadata", "schneider2022_supplement.pdf")
stopifnot(file.exists(pdf_path))

pages <- pdf_text(pdf_path)

lines <- str_split(pages[11], "\n")[[1]]

data_lines <- str_subset(str_trim(lines), "^S\\d{2}")

s1_matrix <- str_split(data_lines, "\\s+", simplify = TRUE)

colnames(s1_matrix) <- c("id", "age", "sex", "ethnicity", "hispanic_latino",
                         "tanner_stage", "status_acne", "iga_score",
                         "sebum_mean", "lotion", "makeup")

s1 <- as_tibble(s1_matrix)

stopifnot(nrow(s1) == 48, ncol(s1) == 11)

s1 <- mutate(s1,
             subject_id   = as.integer(str_remove(id, "S")),   
             age          = as.integer(age),
             sebum_mean   = as.numeric(sebum_mean),           
             iga_score    = as.integer(na_if(iga_score, "n/a")), 
             tanner_stage = paste0("T", tanner_stage)          
)

stopifnot(
  !anyNA(s1$subject_id),
  n_distinct(s1$subject_id) == 48,
  !anyNA(s1$age),
  !anyNA(s1$sebum_mean),
  all(is.na(s1$iga_score) == (s1$status_acne == "Normal"))  # IGA vacío <=> piel normal
)

meta <- left_join(subjects, s1, by = "subject_id", suffix = c("_sra", "_s1"))

stopifnot(
  nrow(meta) == 48,
  !anyNA(meta$age),
  all(meta$tanner_stage_sra == meta$tanner_stage_s1),
  all(meta$status_acne_sra == meta$status_acne_s1)
)

meta <- select(meta, -tanner_stage_s1, -status_acne_s1, -id)
meta <- rename(meta, tanner_stage = tanner_stage_sra, status_acne = status_acne_sra)

meta <- mutate(meta, puberty_group = if_else(tanner_stage %in% c("T1", "T2"), "early", "late"))

stopifnot(
  sum(meta$puberty_group == "early") == 21,
  sum(meta$status_acne == "Normal") == 21
)

metadata <- bind_rows(meta, filter(sra, sample_type != "subject"))

stopifnot(nrow(metadata) == 56)

write_csv(metadata, here("data", "metadata", "metadata.csv"))
