# “Whole Microbiome Analyses of Wastewater Treatment Plants across Europe” (University of Cologne, 2025)

This repository contains all scripts, supplementary data tables, and the final genus-level count matrix used in my Master’s thesis:  
“Whole Microbiome Analyses of Wastewater Treatment Plants across Europe” (University of Cologne, 2025)

This study investigated how latitude and season influence microbial community composition across seven European wastewater treatment plants (WWTPs). We built upon the metagenomic dataset from Becsei et al. (2024; DOI: 10.1038/s41467-024-51957-8), which originally focused solely on bacteria, and extended the analysis to include eukaryotic microorganisms, providing a more complete picture of environmental drivers and potential cross-community interactions.

To ensure full reproducibility, this repository includes Bash scripts for data retrieval, preprocessing, and taxonomic assignment, as well as R scripts used for statistical analyses and visualizations.
For detailed descriptions of individual files, see the Overview.md files in the respective directories (`scripts/` and `supplementary_tables/`).

---

## Overview of Files

### Supplementary Excel Files
- `Supplementary_Table_S1.xlsx`: Sample Details
- `Supplementary_Table_S2.xlsx`: Compound Tables
- `Supplementary_Table_S3.xlsx`: Shannon-Wiener Indices and Relative Abundance Results
- `Supplementary_Table_S4.xlsx`: PERMANOVA Results
- `Supplementary_Table_S5.xlsx`: Plant-specific PERMANOVA Results

##

### Used Scripts
Scripts are numerically ordered to reflect their position in the analysis pipeline:

- `1_Sampling_Period_Plot.r`: Visualizes sample collection periods per WWTP (Figure 1A)
- `2.1_Download.sh`: Downloads raw FASTQ files from ENA based on accession IDs
- `2.2_FastQ_Check.sh`: Runs FastQC for read quality inspection
- `3.1_Mothur_Contig_Assembly.sh`: Assembles contigs and adds non-overlapping forward reads
- `3.2.1_SortMeRNA_Loop.sh`: Loops over samples and dispatches SortMeRNA jobs to the CHEOPS cluster
- `3.2.2_SortMeRNA_Cheops.sh`: Extracts rRNA reads (16S/23S/18S/28S) using SortMeRNA
- `4.1–4.3_Blast_*.sh`: Runs BLASTN against SILVA and PR2 databases (bacteria/eukaryotes)
- `5.1_Blast_Table_Transformation.r`: Cleans BLAST output and extracts genus information
- `5.2_Merge_Tables.r`: Combines cleaned tables into a single genus count matrix
- `5.3_Low_Read_Count_Check.r`: Summarizes low-abundance taxa
- `5.4_Sort_Out_Replicates.r`: Filters out technical replicates
- `6_Rarefaction_Curves.r`: Generates rarefaction curves
- `7.1_Compound_Tables.r`: Calculates total and relative counts per community
- `7.2_Compound_Table_Plot.r`: Visualizes read/genus distributions (Figure 2)
- `8.1_Shannon_Index_Plot_and_Table.r`: Calculates and plots Shannon diversity (Figure 3A)
- `8.2_Relative_Abundance_Barplots.r`: Stacked barplots of top genera (Figure 3B–E)
- `8.3_Calculate_Relative_Abundance_Averages.r`: Console-based genus stats viewer
- `8.4_Linear_Regression.r`: Performs linear regression to detect latitude-associated abundance trends
- `9.1_PCoA.r`: PCoA ordination with environmental fitting (Figure 3F–I)
- `9.2_PERMANOVA.r`: Global and plant-specific PERMANOVA models

##

### Used data
- `filtered_combined_table_PR2_and_SILVA.csv.zip`: Taxonomic count table generated from BLAST results, used for the diversity analyses presented in the R scripts

## Contact
If you have questions, feel free to contact me via [GitHub](https://github.com/NiklasNett)
