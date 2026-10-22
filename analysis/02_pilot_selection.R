# Input:  metadata.csv and SraRunTable.csv
# Output: pilot_runs.txt (one Run per line) and pilot_expected_spots.csv (columns: Run, Spot)
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

# ---- Expected spots per run ----
# Keep only the columns we need
expected_spots <- sra_run |>
  select(Run, Bases, AvgSpotLen)

# Keep only the pilot runs (the 15 in pilot_run)
expected_spots <- expected_spots |>
  filter(Run %in% pilot_run$Run)

# Check types BEFORE dividing: a text column would make the division fail
stopifnot(
  is.numeric(expected_spots$Bases),
  is.numeric(expected_spots$AvgSpotLen),
  all(expected_spots$Bases > 0),
  all(expected_spots$AvgSpotLen > 0)
)

# New column: expected spots
expected_spots <- expected_spots |>
  mutate(Spot = Bases / AvgSpotLen)

# ---- Checks ----
stopifnot(
  # numeric and positive (a text column would give NA or an error silently)
  is.numeric(expected_spots$Bases),
  is.numeric(expected_spots$AvgSpotLen),
  all(expected_spots$Bases > 0),
  all(expected_spots$AvgSpotLen > 0),
  # 15 rows, no NA, no duplicates
  nrow(expected_spots) == 15,
  !anyNA(expected_spots$Spot),
  n_distinct(expected_spots$Run) == 15,
  # same runs, not just the same count
  setequal(expected_spots$Run, pilot_run$Run),
  # sanity check with the run we calculated by hand (19032.7)
  abs(expected_spots$Spot[expected_spots$Run == "SRR20028132"] - 19032.7) < 0.1
)

# ---- Write output ----
write.csv(expected_spots[, c("Run", "Spot")], here("data", "metadata", "pilot_expected_spots.csv"), row.names = FALSE,
          quote = FALSE)

# Check: header + 15 runs
stopifnot(length(readLines(here("data", "metadata", "pilot_expected_spots.csv"))) == 16)
