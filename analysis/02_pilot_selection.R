# Input:  metadata.csv and SraRunTable.csv
# Output: pilot_runs.txt (one Run per line)
#   8 subjects (2 per puberty group x acne status) + 6 negative control + 1 mock

library(here)
library(dplyr)

# ---- Load data ----
metadata <- read.csv(here("data", "metadata", "metadata.csv"))
sra_run <- read.csv(here("data", "metadata", "SraRunTable.csv"))

stopifnot(nrow(metadata) == 56,
          nrow(sra_run) == 56)

# ---- Select subjects ----
set.seed(1)

# Pick 2 random sibjects from each puberty group x acne status combination
pilot_run_subjects <- metadata |>
  filter(sample_type == "subject") |> # leave controls out
  group_by(puberty_group, status_acne) |> # 4 groups (early/late x Acne/Normal)
  slice_sample(n = 2) |>
  ungroup() 

# Chech: All 4 combinations present.
group_counts <- count(pilot_run_subjects, puberty_group, status_acne)

stopifnot(
  nrow(group_counts) == 4,     
  all(group_counts$n == 2)     
)

# ---- Select controls ----
# This keeps ALL 6 negative controls 6 + the mock.
pilot_run_control <- metadata |>
  filter(sample_type == "negative_control" | sample_name == "054_MCC_MSA1005")

# ---- Combine ----
pilot_run <- bind_rows(pilot_run_control, pilot_run_subjects)


# ---- Add file size (Bytes) from SRA table ----
pilot_run_bytes <- sra_run[, c("Run", "Bytes")]

pilot_run <- left_join(pilot_run, pilot_run_bytes, by = "Run")

total_gb <- sum(pilot_run$Bytes) / 1e9
cat("Total: ", round(total_gb, 1), "GB\n")


# ---- Final checks ----
stopifnot(
  nrow(pilot_run) == 15,
  n_distinct(pilot_run$Run) == 15,
  !anyNA(pilot_run$Bytes),
  "054_MCC_MSA1005" %in% pilot_run$sample_name)


# ---- Write output ----
# One Run per line, read later by the bash download script
writeLines(pilot_run$Run, here("data", "metadata", "pilot_runs.txt"))

# Check: the file has 15 Runs
stopifnot(length(readLines(here("data", "metadata", "pilot_runs.txt"))) == 15)
