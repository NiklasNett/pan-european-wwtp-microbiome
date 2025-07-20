# Script Overview

This folder contains all scripts used in the analysis workflow. Each script is named according to its position in the pipeline.

### 1 Sampling Period
- `1_Sampling_Period_Plot.r`: 

### 2 Download and Quality Check
- `2.1_Download.sh`: Downloads raw `.fastq.gz` files from the ENA based on accession numbers; as input .txt data was used containing the to be downloaded ENA Run Accession IDs (were split into multiple .txt for faster and parallel downloading; skript was adapted for each run
- `2.2_FastQ_Check.sh`: Performs quality control using FastQC

### 3 Assembling & Filtering
- `3.1_Mothur_Contig_Assembly.sh`: Merges paired-end reads and applies filtering using Mothur
- `3.2.1_SortMeRNA_Loop.sh`: Filters and preprocesses reads in R (e.g. low-quality removal, relabelling)
- `3.2.2_SortMeRNA_Cheops.sh`: Filters and preprocesses reads in R (e.g. low-quality removal, relabelling)

### 4 Taxonomic Assignment (BLASTN)
- `4.1_Blast_Loop.sh`: 
- `4.2_Blast_SILVA.sh`: Performs BLASTN against PR2 and SILVA databases
- `4.3_Blast_PR2.sh`: Performs BLASTN against PR2 and SILVA databases

### 5 Count Table Generation and Merging
- `5.1_Blast_Table_Transformation.r`: Parses BLAST output and generates tables
- `5.2_Merge_Tables.r`: Merges sample-wise count tables into one unified dataset
- `5.3_Low_Read_Count_Check.r`:
- `5.4_Sort_Out_Replicates.r`:

### 6 Rarefraction Curve
- `6_Rarefaction_Curves.r`: 

### 7 Compound Table
- `7.1_Compound_Tables.r`: Combines read counts and taxonomic data for downstream analyses
- `7.2_Compound_Table_Plot.r`:

### 8 Alpha Diversity & Genus Composition
- `8.1_Shannon_Index_Plot_and_Table.r`: Calculates Shannon-Wiener indices and creates genus-level bar plots
- `8.2_Relative_Abundance_Barplots.r`:
- `8.3_Calculate_Relative_Abundance_Averages.r`:

### 9 Beta Diversity & Statistical Analyses
- `9.1_PCoA.r`: Computes Bray-Curtis dissimilarities and performs ordination (PCoA)
- `9.2_PERMANOVA.r`: Performs PERMANOVA tests and summarizes outputs
                       |
