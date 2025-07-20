# Script Overview

This folder contains all scripts used in the analysis workflow. Each script is named according to its position in the pipeline.
________________________
#### Note:
For several scripts, the workflow was run in chunks (e.g., for `2.1_Download.sh` or `3.1_Mothur_Contig_Assembly.sh`). To ensure faster and more stable processing of large sample sets, accession IDs were split across multiple .txt files. In each script, the filename of the input .txt was manually adjusted before execution. This modular structure allowed for parallel or sequential processing of subsets.
__________________________

### 1 Sampling Period
- `1_Sampling_Period_Plot.r`: Visualizes sampling periods per WWTP based on metadata (Start, End); uses custom colors and scales for consistent appearance.

### 2 Download & Quality Check
- `2.1_Download.sh`: Batch‑downloads raw .fastq.gz files from ENA (European Nucleotide Archive) based on accession numbers. Input list is a .txt file with ENA Run Accession IDs.
- `2.2_FastQ_Check.sh`: Performs quality control using FastQC and saves the reports for later inspection. Used to assess overall read quality and identify problematic samples.

### 3 Assembling & Filtering
- `3.1_Mothur_Contig_Assembly.sh`: Uses Mothur (v1.45.3) to merge overlapping paired-end reads into contigs under stringent error (≤1) and ambiguity (≤1 bp) thresholds. To compensate for non-overlapping reads (likely due to long DNA inserts sequenced at only 150 bp), forward reads were extracted and merged with the Mothur contig output. 
- `3.2.1_SortMeRNA_Loop.sh`: Automates high throughput rRNA extraction by looping over samples, preparing each FASTA file and submitting the SortMeRNA jobs to the CHEOPS cluster with logging.
- `3.2.2_SortMeRNA_Cheops.sh`: Runs SortMeRNA (v4.3.4) per sample on the cluster to isolate 16S 23S 18S and 28S rRNA reads thereby enriching marker genes and reducing later BLAST runtime and noise.

### 4 Taxonomic Assignment (BLASTN)
- `4.1_Blast_Loop.sh`: Dispatches BLASTN jobs against the SILVA and PR2 databases using standardized parameters and uniform file naming for consistent output.
- `4.2_Blast_SILVA.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against SILVA 138 Ref NR.99 retaining the top high-confidence bacterial or archaeal hits for taxonomy assignment.
- `4.3_Blast_PR2.sh`: Runs BLASTN (v2.10.0) of rRNA-enriched reads against PR2 v4.13.0 retaining the top high-confidence eukaryotic hits for taxonomy assignment.

### 5 Count Table Generation & Merging
- `5.1_Blast_Table_Transformation.r`: Cleans and standardizes the BLASTN output (taxonomy split, unwanted taxa removed, placeholder ranks filled, targeted renames) and writes per sample CSVs
- `5.2_Merge_Tables.r`: Combines all cleaned per sample tables and sums read counts per genus to create a unified genus level count matrix as the core dataset for diversity and composition analyses. (stored in the `used_data` directory) 
- `5.3_Low_Read_Count_Check.r`:
- `5.4_Sort_Out_Replicates.r`:

### 6 Rarefraction Curve
- `6_Rarefaction_Curves.r`: 

### 7 Compound Table
- `7.1_Compound_Tables.r`: 
- `7.2_Compound_Table_Plot.r`:

### 8 Alpha Diversity & Relative Abundances
- `8.1_Shannon_Index_Plot_and_Table.r`: s
- `8.2_Relative_Abundance_Barplots.r`:
- `8.3_Calculate_Relative_Abundance_Averages.r`:

### 9 Beta Diversity & Statistical Analyses
- `9.1_PCoA.r`: 
- `9.2_PERMANOVA.r`: 
                       
