# Script Overview

This folder contains all scripts used in the analysis workflow. Each script is named according to its position in the pipeline.

### 1 Download and Quality Check
- `1.1_Download.sh`: Downloads raw `.fastq.gz` files from the ENA based on accession numbers; as input .txt data was used containing the to be downloaded ENA Run Accession IDs (were split into multiple .txt for faster and parallel downloading; skript was adapted for each run
- `1.2_FastQ_Check.sh`: Performs quality control using FastQC

### 2 Preprocessing
- `2.1_Mothur.sh`: Merges paired-end reads and applies filtering using Mothur
- `2.2_R_filtering.R`: Filters and preprocesses reads in R (e.g. low-quality removal, relabelling)

### 3 Taxonomic Assignment (BLASTN)
- `3.1_Prepare_blast.sh`: Prepares input files and formats reference databases
- `3.2_Run_blast.sh`: Performs BLASTN against PR2 and SILVA databases

### 4 Count Table Generation and Merging
- `4.1_blast_parser.R`: Parses BLAST output and generates count tables
- `4.2_merge_tables.R`: Merges sample-wise count tables into one unified dataset

### 5 Rarefraction Curve
- `6_rarefrac.R`: 

### 6 Compound Table
- `6_compound_table.R`: Combines read counts and taxonomic data for downstream analyses

### 7 Alpha Diversity & Genus Composition
- `7_shannon_barplots.R`: Calculates Shannon-Wiener indices and creates genus-level bar plots

### 8 Beta Diversity & Statistical Analyses
- `8_beta_diversity.R`: Computes Bray-Curtis dissimilarities and performs ordination (PCoA)
- `8_permanova.R`: Performs PERMANOVA tests and summarizes outputs

### 9 Seasonal Grouping & Sampling Periods
- `9_sampling_periods.R`: Assigns samples to meteorological seasons and adds timeline metadata                          |
