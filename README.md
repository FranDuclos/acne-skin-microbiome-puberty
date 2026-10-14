# Acne skin microbiome during puberty — an end-to-end replication

Replication of Schneider et al. (2022), *Evolution of the facial skin microbiome during puberty in normal and acne skin*, from raw shotgun metagenomic reads to statistics and machine learning.

> **Status:** 🚧 Block A (pilot) in progress — see [Roadmap](#status--roadmap).

## Overview

Schneider et al. sampled the forehead skin of 48 children and adolescents (ages 7–17), with and without acne, and profiled their microbiome by whole-genome shotgun sequencing. Subjects were staged by puberty (Tanner T1–T5) and sebum levels were measured. The study asks how the facial skin microbiome changes during puberty, and whether it differs between normal and acne skin.

This repository re-runs that analysis on the public data with current tools, documenting every decision along the way.

I chose this paper because it complements my studies and relates directly to my undergraduate thesis on skin metagenomics in acne, both in the type of data and in the type of analysis.

## Learning goals

This is a learning project. The aim is to apply to real data, and be able to defend:

- **Statistics** — non-parametric tests (Wilcoxon), multiple-testing correction
- **Compositional data** — why relative abundances need special treatment (CLR)
- **Diversity** — alpha and beta diversity, PERMANOVA stratified by puberty stage
- **Pipelines** — from raw reads to profiles: QC, host DNA removal, taxonomic and functional profiling
- **Machine learning** — classifying acne vs normal skin (Python, later stage)

The reasoning behind each step is documented in [`docs/`](docs/).

## Data

| | |
|---|---|
| Source | NCBI SRA, BioProject [PRJNA856701](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA856701) |
| Samples | 48 subjects, forehead swabs |
| Sequencing | Illumina NextSeq, 2 × 150 bp paired-end shotgun |
| Metadata | Acne status, Tanner stage, sebum (µg/cm²) |

Raw FASTQ files are **not** included in this repository (size). Run accessions are listed in [`data/metadata/`](data/metadata/), and `workflow/` contains the scripts to download them.

## Pipeline

| Step | Tool | Runs on | Output |
|---|---|---|---|
| 1. Download | SRA Toolkit | WSL / Galaxy | FASTQ |
| 2. Quality control | FastQC, MultiQC | WSL / Galaxy | QC reports |
| 3. Host DNA removal | Bowtie2 + human reference | WSL / Galaxy | Non-human reads |
| 4. Taxonomic profiling | MetaPhlAn 4 | WSL / Galaxy | Relative abundance table |
| 5. Functional profiling | HUMAnN 3 | Galaxy | Pathway abundance table |
| 6. Statistics | R | Local | Tables, figures |
| 7. Classification | Python | Local | Models, metrics |

The **pilot** (6–8 samples) runs locally on WSL2 to learn each tool from the command line. The **full dataset** (48 samples) runs on [Galaxy Europe](https://usegalaxy.eu). Pilot samples are processed both ways, and the outputs are compared as a consistency check.

## Differences from the original study

| | Original | This replication |
|---|---|---|
| Taxonomic profiling | MetaPhlAn2 | MetaPhlAn 4 |
| Functional profiling | HUMAnN2 | HUMAnN 3 |
| Pathway analysis | MicrobiomeAnalyst (web) | R |
| Strain analysis (*C. acnes*) | StrainEst | Not planned (for now) |

Results are not expected to match exactly: newer databases change both the taxonomy and the abundances. Where they differ, the difference is reported and discussed.

## Repository structure

```
├── analysis/          # R scripts, numbered in run order
├── data/
│   ├── metadata/      # SRA run table + cleaned sample metadata
│   └── processed/
│       ├── wsl/       # final profiles from the local pilot
│       └── galaxy/    # final profiles from the full dataset
├── docs/              # decision log and notes
├── envs/              # conda environment for command-line tools
├── results/
│   ├── figures/
│   └── tables/
└── workflow/
    ├── wsl/           # shell scripts (pilot)
    └── galaxy/        # exported Galaxy workflow
```

## Reproducibility

- **R packages:** pinned with [`renv`](https://rstudio.github.io/renv/) (`renv.lock`). Run `renv::restore()` to install them.
- **Command-line tools:** pinned in a conda environment (`envs/`).
- **Galaxy:** the workflow is exported to `workflow/galaxy/` and can be imported into any Galaxy server.

## Status / Roadmap

**Block A — pilot (Oct–Dec 2026)**
- [x] Repository setup
- [ ] Sample metadata table
- [ ] `renv` setup
- [ ] QC (FastQC)
- [ ] Host DNA removal
- [ ] Taxonomic profiling (MetaPhlAn 4)
- [ ] Basic statistics: Wilcoxon, multiple-testing correction, CLR

**Block B — full dataset (Dec 2026–Mar 2027)**
- [ ] All 48 samples on Galaxy
- [ ] Alpha and beta diversity
- [ ] PERMANOVA stratified by puberty stage
- [ ] Differential abundance
- [ ] Functional profiling (HUMAnN 3), porphyrin pathway
- [ ] Comparison with the original results

**Next:** machine learning, acne vs normal (Python)

## Use of AI

Code in this repository is written with AI assistance. The research questions and the analysis design are mine. Every piece of code is reviewed before it is used: what goes in, what comes out, and how to check that it's right. The reasoning behind each decision is in [`docs/`](docs/).

## Citation

Original study:

> Schneider AM, Nolan ZT, Banerjee K, et al. Evolution of the facial skin microbiome during puberty in normal and acne skin. *J Eur Acad Dermatol Venereol.* 2023;37(1):166–175. doi:[10.1111/jdv.18616](https://doi.org/10.1111/jdv.18616)

## License

Code: [MIT](LICENSE). Data belong to their original authors and are available from NCBI SRA.

## Author

**Francisco Duclos** — Biotechnology & Bioinformatics student

[GitHub](https://github.com/FranDuclos) · [LinkedIn](https://www.linkedin.com/in/francisco-duclos-199093217/)
