# Script Overview

This folder contains all scripts used in the analysis workflow for my Master’s Thesis *"Whole Microbiome Analyses of Wastewater Treatment Plants 
across Europe"*. Each script is numerically prefixed to indicate its position within the pipeline. A detailed description of each script is provided below:

##

#### Note:
For several scripts (e.g., for `2.1_Download.sh` or `3.1_Mothur_Contig_Assembly.sh`), the workflow was executed in chunks to improve performance and stability when handling large sample sets. Accession IDs were distributed across multiple `.txt` files and each script was manually adjusted to reference the appropriate file. This modular approach enabled both parallel and sequential processing of sample subsets.
__________________________

### 1 Sampling Period
- `1_Sampling_Period_Plot.r`: Visualizes sampling periods per WWTP (Wastewater Treatment Plant) using collection metadata (Figure 1A).

##

### 2 Download & Quality Check
- `2.1_Download.sh`: Batch‑downloads raw `.fastq.gz` files from the ENA (European Nucleotide Archive) using `.txt` input files containing ENA Run Accession IDs.
- `2.2_FastQ_Check.sh`: Runs FastQC to assess overall read quality and generate per sample reports for later inspection.

##

### 3 Assembling & Filtering
- `3.1_Mothur_Contig_Assembly.sh`: Uses Mothur (v1.45.3) to assemble overlapping paired-end reads into contigs with strict quality filters (max. 1 expected error, max. 1 ambiguous base). To account for the high number of non-overlapping reads, likely caused by long DNA inserts sequenced at only 150 bp, forward reads were extracted and appended to the contig output to maximize data retention.
- `3.2.1_SortMeRNA_Loop.sh`: Automates high-throughput rRNA extraction by looping over samples, preparing individual FASTA files, and submitting SortMeRNA jobs to the CHEOPS cluster via SLURM. Designed for large-scale processing.
- `3.2.2_SortMeRNA_Cheops.sh`: Runs SortMeRNA (v4.3.4) per sample on the CHEOPS cluster to isolate 16S, 23S, 18S, and 28S rRNA sequences. This step enriches phylogenetic marker genes and reduces background noise and runtime in downstream BLASTN analyses.
 
##

### 4 Taxonomic Assignment (BLASTN)
- `4.1_Blast_Loop.sh`: Dispatches BLASTN jobs against the SILVA and PR2 databases using uniform query formatting, consistent file naming, and standardized parameters to ensure reproducible and comparable outputs.
- `4.2_Blast_SILVA.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against the SILVA 138 Ref NR.99 database, retaining only the top high-confidence bacterial and archaeal hits for taxonomic assignment.
- `4.3_Blast_PR2.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against the PR2 v4.13.0 database, retaining only the top high-confidence eukaryotic hits for taxonomic assignment.

##

### 5 Count Table Generation & Merging
- `5.1_Blast_Table_Transformation.r`: Cleans and standardizes BLASTN output by splitting taxonomy, removing unwanted taxa, filling placeholder ranks, applying targeted renaming, and writing per sample CSVs.
- `5.2_Merge_Tables.r`: Combines all cleaned per sample tables and sums read counts per genus to create a unified genus-level count matrix, used as the core dataset for downstream diversity and composition analyses (stored in the `used_data` directory). 
- `5.3_Low_Read_Count_Check.r`: Summarizes genus-level read counts for prokaryotes and eukaryotes, including the distribution of genera with 1–20 reads and the total number of unique genera per supergroup, to justify the applied low-abundance filtering threshold.
- `5.4_Sort_Out_Replicates.r`: Matches the accessions from the merged count table with those used in the ARG (Antibiotic Resistance Genes) analyses of the original study (Becsei et al., 2024) to identify and remove technical replicates, ensuring balanced sample representation across all WWTPs.

##

### 6 Rarefaction Curve
- `6_Rarefaction_Curves.r`: Generates sample-level rarefaction curves for the full dataset and for optional prokaryote/eukaryote subsets to assess saturation of sequencing depth.

##

### 7 Compound Table
- `7.1_Compound_Tables.r`:Calculates absolute and relative read and genus counts per WWTP and overall, for each microbial community (Bacteria, Archaea, Metazoa, Protists, and Fungi), providing a comparative baseline of microbial composition across sites (Supplementary_Table_S2.xlsx).
- `7.2_Compound_Table_Plot.r`: Generates a bar plot based on the compound tables to visualize relative read and genus counts across microbial communities and WWTPs (Figure 2).

##

### 8 Alpha Diversity & Relative Abundances
- `8.1_Shannon_Index_Plot_and_Table.r`: Calculates Shannon-Wiener indices per microbial community, WWTP, and sampling date to assess genus-level richness and evenness. Results are saved as CSVs and visualized in a faceted time-series plot with LOESS smoothing (Figure 3A).
- `8.2_Relative_Abundance_Barplots.r`: Calculates per sample relative genus abundances, selects the top 10 genera per community, and groups remaining taxa as “Others” to generate faceted stacked bar plots (Figures 3B–E). Merges results with Shannon indices into a combined Excel file (Supplementary_Table_S3.xlsx).
- `8.3_Calculate_Relative_Abundance_Averages.r`: Interactive script allowing the user to select a community, plant and genus. Reports mean relative abundance, standard deviation and number of samples in which the genus was detected (console output only).
- `8.4_Linear_Regression.r`: Interactive script allowing the user to select a genus and perform linear regression to assess abundance gradients across WWTPs ordered by latitude.

##

### 9 Beta Diversity & Statistical Analyses
- `9.1_PCoA.r`: Normalizes genus counts, computes Bray–Curtis dissimilarities, performs PCoA (Principal Coordinates Analysis) and fits latitude and the ten most abundant genera as environmental vectors. Outputs per community ordination plots (Figures 3F–I) and coordinate CSVs for subsequent PERMANOVA.
- `9.2_PERMANOVA.r`: Runs global adonis2 models (by terms) per microbial community using Latitude, Plant, Season, and PCoA1 scores from the other microbial communities as predictors. Also performs plant-specific PERMANOVAs using Season and PCoA1 scores from the other microbial communities. Global results are saved to Supplementary_Table_S4.xlsx; plant-specific summaries to Supplementary_Table_S5.xlsx.
                       
