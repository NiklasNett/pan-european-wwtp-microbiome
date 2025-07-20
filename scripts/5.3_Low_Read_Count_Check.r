# Author: Niklas Nett
# Created: 2025-01-23
# Last updated: 2025-03-03

# Purpose: Summarize genus-level abundances for prokaryotic and eukaryotic communities based on the merged genus-level count table. 
#          Provides insight into the distribution of genera with low read counts (1–20 reads)
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
# Output:  - Summary tables printed to console:
#            → Number of genera per read count (1–20) for Eukaryotes and Prokaryotes
#            → Total number of unique genera per Superdomain

# Load packages
library(dplyr)              

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# Read input file (merged table)
data <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE, stringsAsFactors = FALSE)

# create Superdomain
data <- data %>%
  mutate(Domain = sub("^.*\\|", "", Domain)) %>%
  mutate(Superdomain = case_when(
    Domain %in% c("Archaea", "Bacteria") ~ "Prokaryote",
    TRUE ~ "Eukaryote"  
  )) 

# split prokaryotes and eukaryotes into two separate data frames
prokaryotes <- data %>%
  filter(Superdomain == "Prokaryote")

eukaryotes <- data %>%
  filter(Superdomain == "Eukaryote")

# Eukaryotes: group by (unique) Genus and sum Number of Reads
eukaryotes_summary <- eukaryotes %>%
  group_by(Genus) %>%
  summarise(NumberOfReads = sum(NumberOfReads, na.rm = TRUE)) %>% # sum reads per genus
  group_by(NumberOfReads) %>%
  summarise(NumberOfGenera = n()) %>% # counts how many genera per number of reads
  arrange(NumberOfReads) # sort ascending by number of reads

# show Number of Genera for 1 to 20 reads
eukaryotes_20 <- head(eukaryotes_summary, 20)

print("Eukaryotes - Number of Genera per read")
print(eukaryotes_20)

# calculate total number of unique genera for eukaryotes
eukaryotes_total <- sum(eukaryotes_summary$NumberOfGenera)
print("Eukaryotes - total number of genera:")
print(eukaryotes_total)

# Prokaryotes: group by (unique) Genus and sum Number of Reads
prokaryotes_summary <- prokaryotes %>%
  group_by(Genus) %>%
  summarise(NumberOfReads = sum(NumberOfReads, na.rm = TRUE)) %>% # sum reads per genus
  group_by(NumberOfReads) %>%
  summarise(NumberOfGenera = n()) %>% # counts how many genera per number of reads
  arrange(NumberOfReads) # sort ascending by number of reads

# show Number of Genera for 1 to 20 reads
prokaryotes_20 <- head(prokaryotes_summary, 20)

print("Prokaryotes - Number of Genera per read")
print(prokaryotes_20)

# calculate total number of unique genera for prokaryotes
prokaryotes_total <- sum(prokaryotes_summary$NumberOfGenera)

print("Prokaryotes - total number of genera:")
print(prokaryotes_total)

