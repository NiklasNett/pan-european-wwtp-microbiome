# Author: Niklas Nett
# Created: 2025-05-21
# Last updated: 2025-06-11

# Purpose: Remove unused replicate samples from the merged genus-level count table to match the sample selection used in the ARG analyses of the original study (Becsei et al., 2024).
#          Ensures a balanced representation across all WWTPs by excluding replicates
# Input:   - Supplementary_table.xlsx (Sheets: "Supplementary Data 1" and "Supplementary Data 3")
#          → Metadata and sample IDs used in ARG analysis
#          - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
# Output:  - Matched_SampleID-AccessionIDs.csv (samples used in ARG study)
#          - Unmatched_AccessionIDs.csv (samples excluded from ARG study)
#          - filtered_combined_table_PR2_and_SILVA.csv (updated version with filtered replicates removed)

# Load packages
library(readxl)
library(dplyr)
library(stringr)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")  

## Goal: filter out sample id (used for ARG research in the original Paper) --> there only one Replica was used; filter out same samples for our research (even out playing field for all plants)
## for reference see supplementary table from the original Paper (Becsei et al, 2024)

# Sheet with all informations for AccessionIDs (ENA RUN ACCESSION) and corresponding metadata (Collection Date, Plant etc.)
data <- read_excel("Supplementary_table.xlsx", sheet = "Supplementary Data 1") %>%
  mutate(
    ENA_ALIAS = as.character(ENA_ALIAS),
    REPLICA   = as.character(REPLICA),
    sample_id = str_c(ENA_ALIAS, "_", REPLICA) # sample id construct of ENA_ALIAS and REPLICA Number
  )

# Pull out sample ids used for ARG research
sample_id_arg <- read_excel("Supplementary_table.xlsx", sheet = "Supplementary Data 3") %>%
  pull(sample_id) |>
  unique()

## create two lists --> one for found sample id and one for unmatched ones 

matched_df <- filter(data, sample_id %in% sample_id_arg)
unmatched_df <- filter(data, !sample_id %in% sample_id_arg)

# Check if extraction worked (Number of Unmatched should be 43 and matched 235)
cat("Matched:", nrow(matched_df),   "rows\n")
cat("Unmatched:", nrow(unmatched_df), "rows\n")

# save dataframes as csv (for further checking if everything was matched and extracted successfully)
write.csv(select(matched_df,
                 sample_id,
                 ENA_SAMPLE_ACCESSION,
                 ENA_ALIAS,
                 ENA_RUN_ACCESSION,
                 REPLICA),
          "Matched_SampleID-AccessionIDs.csv",
          row.names = FALSE)

write.csv(select(unmatched_df,
                 ENA_SAMPLE_ACCESSION,
                 ENA_ALIAS,
                 ENA_RUN_ACCESSION,
                 REPLICA),
          "Unmatched_AccessionIDs.csv",
          row.names = FALSE)

## delete unmatched Replicates from "filtered_combined_table_PR2_and_SILVA.csv"

# Read input file (merged table)
merged_table <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE)

# extract accessions to remove
accessions_to_remove <- unmatched_df$ENA_RUN_ACCESSION

# delete selected accessions from count table
merged_table_cleaned <- subset(merged_table, !(AccessionID %in% accessions_to_remove))

# check if right amount of accessions were removed (43)
removed_ids <- unique(accessions_to_remove)

cat("Number of deleted AccessionIDs:", length(removed_ids), "\n")
cat("Deleted AccessionIDs:", removed_ids, "\n")

# save filtered count table without Replicas as csv
write.csv(merged_table_cleaned, "filtered_combined_table_PR2_and_SILVA.csv", row.names = FALSE)

