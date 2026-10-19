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