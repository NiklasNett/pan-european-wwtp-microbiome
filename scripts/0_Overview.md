# Script Overview

This folder contains all scripts used in the analysis workflow. Each script is named according to its position in the pipeline.
________________________
#### Note:
For several scripts, the workflow was run in chunks (e.g., for `2.1_Download.sh` or `3.1_Mothur_Contig_Assembly.sh`). To ensure faster and more stable processing of large sample sets, accession IDs were split across multiple .txt files. In each script, the filename of the input .txt was manually adjusted before execution. This modular structure allowed for parallel or sequential processing of subsets.
__________________________

### 1 Sampling Period
- `1_Sampling_Period_Plot.r`: Visualizes sampling periods per WWTP based on metadata (Start, End); uses custom colors and scales for consistent appearance.

### 2 Download & Quality Check
- `2.1_Download.sh`: Downloads raw .fastq.gz files from ENA (European Nucleotide Archive) based on accession numbers; input is a .txt file with ENA Run Accession IDs.
- `2.2_FastQ_Check.sh`: Performs quality control using FastQC and saves the reports for later inspection.

### 3 Assembling & Filtering
- `3.1_Mothur_Contig_Assembly.sh`: 
- `3.2.1_SortMeRNA_Loop.sh`:
- `3.2.2_SortMeRNA_Cheops.sh`: 

### 4 Taxonomic Assignment (BLASTN)
- `4.1_Blast_Loop.sh`: 
- `4.2_Blast_SILVA.sh`: 
- `4.3_Blast_PR2.sh`: 

### 5 Count Table Generation & Merging
- `5.1_Blast_Table_Transformation.r`: 
- `5.2_Merge_Tables.r`: 
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
                       
