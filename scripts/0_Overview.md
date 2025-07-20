# Script Overview

This folder contains all scripts used in the analysis workflow. Scripts are numerically prefixed to reflect execution order.
________________________
#### Note:
For several scripts, the workflow was run in chunks (e.g., for `2.1_Download.sh` or `3.1_Mothur_Contig_Assembly.sh`). To ensure faster and more stable processing of large sample sets, accession IDs were split across multiple .txt files. In each script, the filename of the input .txt was manually adjusted before execution. This modular structure allowed for parallel or sequential processing of subsets.
__________________________

### 1 Sampling Period
- `1_Sampling_Period_Plot.r`: Visualizes sampling periods for each WWTP (Wastewater Treatment Plant) based on metadata (Figure 1).

### 2 Download & Quality Check
- `2.1_Download.sh`: Batch‑downloads raw `.fastq.gz` files from ENA (European Nucleotide Archive) based on accession numbers. Input list is a .txt file with ENA Run Accession IDs.
- `2.2_FastQ_Check.sh`: Performs quality control using FastQC and saves the reports for later inspection. Assesses overall read quality and identifies problematic samples.

### 3 Assembling & Filtering
- `3.1_Mothur_Contig_Assembly.sh`: Uses Mothur (v1.45.3) to merge overlapping paired-end reads into contigs under stringent error (≤1) and ambiguity (≤1 bp) thresholds. To compensate for non-overlapping reads (likely due to long DNA inserts sequenced at only 150 bp), forward reads were extracted and appended to the Mothur contig output. 
- `3.2.1_SortMeRNA_Loop.sh`: Automates high-throughput rRNA extraction by looping over samples, preparing each FASTA file and submitting the SortMeRNA jobs to the CHEOPS cluster with logging.
- `3.2.2_SortMeRNA_Cheops.sh`: Runs SortMeRNA (v4.3.4) per sample on the cluster to isolate 16S, 23S, 18S, and 28S rRNA reads, thereby enriching marker genes and reducing later BLAST runtime and noise.

### 4 Taxonomic Assignment (BLASTN)
- `4.1_Blast_Loop.sh`: Dispatches BLASTN jobs against the SILVA and PR2 databases using standardized parameters and uniform file naming for consistent output.
- `4.2_Blast_SILVA.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against SILVA 138 Ref NR.99 retaining the top high-confidence bacterial or archaeal hits for taxonomy assignment.
- `4.3_Blast_PR2.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against PR2 v4.13.0 retaining the top high-confidence eukaryotic hits for taxonomy assignment.

### 5 Count Table Generation & Merging
- `5.1_Blast_Table_Transformation.r`: Cleans and standardizes the BLASTN output (taxonomy split, unwanted taxa removed, placeholder ranks filled, targeted renames) and writes per sample CSVs.
- `5.2_Merge_Tables.r`: Combines all cleaned per sample tables and sums read counts per genus to create a unified genus level count matrix as the core dataset for diversity and composition analyses. (stored in the `used_data` directory) 
- `5.3_Low_Read_Count_Check.r`: Summarizes genus read counts for prokaryotes and eukaryotes (distribution of genera at 1–20 reads and total unique genera per superdomain) to justify low-abundance filtering; prints summaries to console only.
- `5.4_Sort_Out_Replicates.r`: Matches merged count table accessions to the accessions used in the ARG (Antibiotic Resistance Genes) analyses of the original study (Becsei et al., 2024), to filter out and remove replicates to ensure a balanced representation across all WWTPs.

### 6 Rarefaction Curve
- `6_Rarefaction_Curves.r`: Generates sample-level rarefaction curves for all data and optional prokaryote/eukaryote subsets to assess sequencing depth saturation.

### 7 Compound Table
- `7.1_Compound_Tables.r`: Calculates per WWTP and overall summarizes absolute and relative read and genus counts for each microbial community (Bacteria, Archaea, Metazoa, Protists, and Fungi) to provide a comparative baseline of the microbial composition in the WWTPs (Supplementary_Table_S2.xlsx).
- `7.2_Compound_Table_Plot.r`: Generates a bar plot based on the compound tables displaying relative read and genus counts (Figure 2).

### 8 Alpha Diversity & Relative Abundances
- `8.1_Shannon_Index_Plot_and_Table.r`: Calculates Shannon-Wiener Indices to analyze richness and evenness for each microbial community per WWTP and sampling date. Results were exported as per community CSV files and visualized in a faceted time-series plot with LOESS smoothing (Figure 3A).
- `8.2_Relative_Abundance_Barplots.r`: Calculates per sample relative genus abundances, selects the top 10 genera per community and groups the rest as Others to create faceted stacked barplots (Figures 3B–E) and merges results with Shannon indices into a combined Excel file (Supplementary_Table_S3.xlsx).
- `8.3_Calculate_Relative_Abundance_Averages.r`: Interactive script allowing the user to select a community, plant and genus then reports mean relative abundance, standard deviation and number of samples in which the genus was detected (console output only).

### 9 Beta Diversity & Statistical Analyses
- `9.1_PCoA.r`: Normalizes genus counts, computes Bray–Curtis dissimilarities, performs PCoA (Principal Coordinates Analysis), fits latitude and top 10 genera as environmental vectors and outputs per community ordination plots and coordinate CSVs for PERMANOVA (Figures 3F–I).
- `9.2_PERMANOVA.r`: Runs global adonis2 models (by terms) per community (Latitude + Plant + Season + PCoA1 scores from the other communities) plus plant-specific models (Season + PCoA1 scores from the other communities) to partition variance. Global results are saved to Excel Supplementary_Table_S4.xlsx and plant-specific summaries are provided as Supplementary_Table_S5.xlsx. 
                       
