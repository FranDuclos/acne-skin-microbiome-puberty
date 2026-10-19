## D1 - Getting the metadata (2026-10-14)

**Decision:** We used both the SRA, to get the Runs, and Table S1 from the supplementary tables, and joined them by subject number to build `metadata.csv`.

**Why:** SraRunTable.csv has the Run, the subject ID, the Tanner stage and whether the subject has acne or not (all inside `Sample Name`, e.g. `036_T2_Normal`), but it has no clinical data. Table S1 does have the clinical data (age, sex, iga_score, sebum, lotion, makeup), but it doesn't have the Run. So we decided to join both tables: S1 brings the clinical data and the SRA brings the Runs, which are what later let us connect the FASTQ files to each subject.

Since Tanner stage and acne status show up in both tables, I used them as a check: if both sources disagreed for any subject, something was wrong. All 48 matched.

Also:
- I kept the 6 negative controls and the 2 mocks (56 samples in total), flagged in the `sample_type` column. The controls are useful to check for contamination, and the mocks to validate the pipeline.
- I added `puberty_group` (early = T1–T2, late = T3–T5), same as the paper, because some groups have only 1 or 2 kids (T2_Acne = 2, T3_Normal = 2, T4_Normal = 1), and you can't do statistics like that.

**Alternatives considered:**
- Using only the SRA: it has no clinical data.
- Using only S1: it has no Runs, so I couldn't connect the FASTQ files to each subject.
- To get S1 out of the PDF: transcribing it by hand (fast, but error-prone and not reproducible) or using `tabulapdf`. I chose `pdftools` because the script documents where every value comes from.

**Notes:** The PDF has to be downloaded by hand because PMC blocks direct downloads from RStudio. It's not uploaded to the repo because it's copyrighted by the journal; only the extracted CSV is.

**Source:** BioProject PRJNA856701 (SraRunTable), Table S1 of the supplement (page 11), and the paper's methods section for the puberty group cutoff.

## D2 - Pilot sample selection (2026-10-19)

**Decision:** The pilot has 15 runs: 8 subjects (2 for each puberty group x acne status combination, picked at random with `set.seed(1)`), all 6 negative controls, and the mock community MSA-1005.

**Why:** I picked 2 subjects per combination (early/late x Acne/Normal) so the pilot already has the 4 groups I'm going to compare later. The selection is random so I don't bias it without noticing (for example by picking the smallest files), and the seed makes it reproducible: running the script again gives the same 8 subjects.

I kept all 6 negative controls because they're cheap (~0.8 GB all together, less than half a subject) and with only one control you can't tell real contamination from noise. You need several to see which species show up consistently. There are also two types (`NegCtrl_1-5` and `NegExt6B`, probably an extraction blank), so I can check whether they behave differently.

I chose the mock MSA-1005 because it's a skin microbiome mix: 6 species at 16.7% each, including *C. acnes* and *S. epidermidis*. Since I know what should come out, I can check whether MetaPhlAn gets it right on the bacteria that matter for this project.

The total is ~14 GB, which fits on my disk if I process one sample at a time.

**Alternatives considered:**
- Picking samples by hand or by file size: easier, but it can bias the selection.
- 1 negative control instead of 6: saves almost nothing and doesn't let me evaluate contamination.
- Mock MSA-1002 (20 strains, 5% each): not skin-specific, less useful for validating this pipeline.
- Fewer than 8 subjects: then I couldn't have the same number in each of the 4 groups.

**Source:** SraRunTable.csv (`Bytes` column for file sizes), ATCC product pages for [MSA-1005](https://www.atcc.org/products/msa-1005) and [MSA-1002](https://www.atcc.org/products/msa-1002).