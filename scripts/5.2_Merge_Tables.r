# Author: Niklas Nett
# Created: 2025-01-23
# Last updated: 2025-07-14

# Purpose: Merge and process taxonomic classification tables from PR2 and SILVA BLAST results.
#          Includes read-level aggregation, removal of taxa with low read count (based on 4.3_Low_Read_Count_Check.r), annotation and consistency validation. 
#          Final output is a unified genus-level table per sample.

# Input:   - Multiple *_rRNA_Blast_P2_filtered.csv and *_rRNA_Blast_SILVA_filtered.csv files (stored in defined directories)
#          - Sample metadata file: DetailsSamples.csv (semicolon-separated)
# Output:  - Combined and filtered genus-level table with read counts per sample and microbial community annotations
#          - Output file saved as: filtered_combined_table_PR2_and_SILVA.csv
#          - Logfile tracking all steps and warnings

# Load packages
library(dplyr)
library(readr)
library(stringr)

# Define directories
working_dir <- "/home/anna/WorkingDir/Niklas"
output_dir <- "/home/anna/nas-subdirectory/Niklas/MergedList_PR2_and_SILVA"

# List all PR2 and SILVA directories
pr2_dirs <- c(
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_denmark1",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_denmark2",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_denmark3",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_hungary",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_italy",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_netherlands"
)

silva_dirs <- c(
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_denmark1",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_denmark2",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_denmark3",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_hungary",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_italy",
  "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_netherlands"
)

logfile <- file.path(working_dir, "script_log.txt")

# create logfile
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ", message, "\n")
  cat(log_entry, file = logfile, append = TRUE)
  cat(log_entry)
}

log_message("Start script.")

# Collect all PR2 and SILVA files from the listed directories
pr2_files <- unlist(lapply(pr2_dirs, function(dir) {
  list.files(dir, pattern = "_rRNA_Blast_P2_filtered\\.csv$", full.names = TRUE)
}))

silva_files <- unlist(lapply(silva_dirs, function(dir) {
  list.files(dir, pattern = "_rRNA_Blast_SILVA_filtered\\.csv$", full.names = TRUE)
}))

# Ensure data exist
if (length(pr2_files) == 0) {
  log_message("Error: No PR2 data found.")
  stop("No PR2 data found in defined directory.")
}
if (length(silva_files) == 0) {
  log_message("Error: No SILVA data found.")
  stop("No SILVA data found in defined directory.")
}

log_message("Found PR2 and SILVA data.")

# Load PR2 data (& extract AccessionID from ReadID)
log_message("Start loading PR2 data.")
pr2_data <- bind_rows(lapply(pr2_files, function(file) {
  data <- read_csv(file, show_col_types = FALSE) #show_col_types = FALSE show less in console (declutter)
  data %>% mutate(Source = "PR2", AccessionID = str_extract(ReadID, "^[^.]+")) #extract everything until . is reached
}))

# Load SILVA data (& extract AccessionID from ReadID)
log_message("Start loading SILVA data.")
silva_data <- bind_rows(lapply(silva_files, function(file) {
  data <- read_csv(file, show_col_types = FALSE) #show_col_types = FALSE show less in console (declutter)
  data %>% mutate(Source = "SILVA", AccessionID = str_extract(ReadID, "^[^.]+")) #extract everything until . is reached
}))

log_message("Data successfully loaded.")

# delete duplicates based on ReadID
pr2_data <- pr2_data %>% distinct(ReadID, .keep_all = TRUE) #keep_all=TRUE keeps all columns for each ReadIDs
silva_data <- silva_data %>% distinct(ReadID, .keep_all = TRUE)

log_message("Deleted duplicates based on ReadID.")

# calculate NumberOfReads per Genus for each sample 
pr2_genus_read_counts <- pr2_data %>%
  group_by(AccessionID, Domain, Phylum, Class, Order, Family, Genus) %>% # grouping all AccessionID with same taxonomies
  summarise(NumberOfReads = n(), .groups = "drop") # summarise(): aggregates  data within each group; n():  number of rows in each group is calculated & shown in new NumberOfReads column

silva_genus_read_counts <- silva_data %>%
  group_by(AccessionID, Domain, Phylum, Class, Order, Family, Genus) %>% # grouping all AccessionID with same taxonomies
  summarise(NumberOfReads = n(), .groups = "drop") # summarise(): aggregates  data within each group; n():  number of rows in each group is calculated & shown in new NumberOfReads column

log_message("Calculated NumberOfReads per Genre for each sample.")

# load sample details
sample_details_file <- file.path(working_dir, "DetailsSamples.csv")
sample_details <- read_delim(sample_details_file, delim = ";", show_col_types = FALSE)

# add sample details to each AccessionID
pr2_final_data <- pr2_genus_read_counts %>%
  left_join(sample_details, by = c("AccessionID" = "ENA_RUN_ACCESSION"))

silva_final_data <- silva_genus_read_counts %>%
  left_join(sample_details, by = c("AccessionID" = "ENA_RUN_ACCESSION"))

# Merge PR2 and SILVA tables
combined_data <- bind_rows(pr2_final_data, silva_final_data)
log_message("PR2 and SILVA tables successfully merged.")

# Validation step: Check if sum NumberOfReads matches with ammount reads of original file
validate_reads <- function(accession_id) {
  # Calculate number of reads in original files
  pr2_reads <- sum(filter(pr2_genus_read_counts, AccessionID == accession_id)$NumberOfReads, na.rm = TRUE)
  silva_reads <- sum(filter(silva_genus_read_counts, AccessionID == accession_id)$NumberOfReads, na.rm = TRUE)
  total_reads <- pr2_reads + silva_reads

  # calculate number of reads from merged table
  calculated_reads <- sum(filter(combined_data, AccessionID == accession_id)$NumberOfReads, na.rm = TRUE)

  # Check if values match 
  if (total_reads != calculated_reads) {
    log_message(
      paste0("Error: Number of Reads don't match ", accession_id, 
             ": Expected: ", total_reads, ", Calculated: ", calculated_reads)
    )
  } else {
    log_message(paste0("Validation successful for accession ", accession_id, 
                       ": Expected: ", total_reads, ", Calculated: ", calculated_reads))
  }
}
# do validation-check for each AccessionID (makes it easier to track errors)
unique_accessions <- unique(combined_data$AccessionID)
lapply(unique_accessions, validate_reads)

# Replace "Rhogostoma-lineage" to "Rhogostoma" 
combined_data$Genus <- gsub("Rhogostoma-lineage", "Rhogostoma", combined_data$Genus)

# Filter step: Remove entries with low read counts: delete rows with NumberOfReads <= 6
combined_data <- combined_data %>%
filter(NumberOfReads > 5)

log_message("Filtered out entries with read count ≤ 5.")

# Clean up Domain column (delete everything before "|")
combined_data <- combined_data %>%
  mutate(Domain = sub("^.*\\|", "", Domain))

log_message ("Cleaned up Domain column.")

# Create Superdomain, Database, and Microbial_Community columns
combined_data <- combined_data %>%
  # create Superdomain (based on Domain)
  mutate(Superdomain = case_when(
    Domain %in% c("Archaea", "Bacteria") ~ "Prokaryote",
    TRUE ~ "Eukaryote"  
  )) %>%
  
  # create Database column
  mutate(Database = ifelse(Superdomain == "Prokaryote", "SILVA", "PR2")) %>%
  
  # create Microbial_Community column
  mutate(Microbial_Community = case_when(
    Database == "SILVA" & Domain == "Bacteria" ~ "Bacteria",
    Database == "SILVA" & Domain == "Archaea" ~ "Archaea",
    Database == "PR2" & Phylum == "Metazoa" ~ "Metazoa",
    Database == "PR2" & Phylum == "Fungi" ~ "Fungi",
    Database == "PR2" ~ "Protists",
    TRUE ~ "Unknown"
  )) %>%
  
  # Reorder columns
  select(
    AccessionID, Database, Superdomain, Microbial_Community, Domain, Phylum, everything()
  )

log_message("Created and reordered Superdomain, Database, and Microbial_Community columns.")

# Save results
output_file <- file.path(output_dir, "filtered_combined_table_PR2_and_SILVA.csv")
write_csv(combined_data, output_file)
log_message(paste("Saved merged table:", output_file))

log_message("Pipeline successfully completed.")


