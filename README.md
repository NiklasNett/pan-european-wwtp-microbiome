# “Whole Microbiome Analyses of Wastewater Treatment Plants across Europe” (University of Cologne, 2025)

This repository contains the shell and R scripts, supplementary Excel files, and the count table derived from BLAST results that were used for the analyses in my Master’s thesis:  
“Whole Microbiome Analyses of Wastewater Treatment Plants across Europe” (University of Cologne, 2025)

This study aimed to investigate how latitude and season shape microbial community composition across seven European wastewater treatment plants (WWTPs). Using metagenomic data from Becsei et al. (2024; DOI: 10.1038/s41467-024-51957-8), which originally focused solely on bacteria, we expanded the analysis to include eukaryotic microorganisms, offering a more comprehensive view of shaping factors and potential cross-community interactions.

To ensure full reproducibility, this repository includes Bash scripts for data retrieval, preprocessing, and taxonomic assignment, as well as R scripts used for statistical analyses and visualizations.

## Overview of Files

### Supplementary Excel Files
- `01_QC_Filtering.R`: Quality control and filtering of raw sequencing reads
- `02_SortMeRNA_Filtering.sh`: Removes rRNA sequences using SortMeRNA on HPC
- `03_Taxonomic_Annotation_BLAST.R`: Annotates contigs via BLAST against PR2 and SILVA
- `04_AlphaDiversity_Plots.R`: Calculates and plots Shannon diversity indices
- `filtered_combined_table_PR2_and_SILVA.csv`: Main merged table with taxonomy annotations and abundances

### Used Scripts


###
- `filtered_combined_table_PR2_and_SILVA.csv.zip`: containing the count table derived from BLAST results used in the diverity analysis scripts

## Contact
If you have questions, feel free to contact me via [GitHub](https://github.com/NiklasNett)
