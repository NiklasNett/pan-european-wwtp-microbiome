# Author: Niklas Nett
# Created: 2025-03-25
# Last updated: 2025-07-18

# Purpose: Perform PERMANOVA analyses ("by terms") to test for associations between microbial community composition and potential explanatory variables.
#          Used Terms:
#            - LATITUDE, SEASON, PLANT
#            - Cross-community structure: PCoA1 axes of other microbial communities
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
#          - PCoA_Coordinates_*.csv (coordinates from genus-level Bray-Curtis PCoA for each community)
# Output:  - Global PERMANOVA results for all samples (PERMANOVA_results.xlsx; uploaded as Supplementary_Table_S4.xlsx)
#          - Plant-specific PERMANOVA results (printed to console; combined and uploaded as Supplementary_Table_S5.xlsx)

# Load packages
library(dplyr)
library(tidyr)
library(vegan)      
library(lubridate)  
library(tibble) 
library(writexl)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# Read input file (merged table)
data <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE, sep = ",", stringsAsFactors = FALSE)

# rename plants
data <- data %>%
  mutate(PLANT = recode(PLANT, 
                        "Rensningsanlaeg Damhusaaen"                    = "Copenhagen_RD",
                        "Rensningsanlaeg Avedoere"                      = "Copenhagen_RA",
                        "Rensningsanlaeg Lynetten"                      = "Copenhagen_RL",
                        "Dokhaven"                                      = "Rotterdam",
                        "ATO2 Wastewater Treatment Plant"               = "Rome",
                        "Gruppo HERA"                                   = "Bologna",
                        "Budapesti Kozponti Szennyviztisztito Telep"    = "Budapest"))


# read in PCoA-Coordinates: Bacteria & merge with data
pcoa_bac <- read.csv("PCoA_Coordinates_Bacteria.csv", stringsAsFactors = FALSE)
colnames(pcoa_bac) <- c("PCoA1_Bacteria", "PCoA2_Bacteria", "AccessionID")
pcoa_bac$AccessionID <- as.character(pcoa_bac$AccessionID)
data <- dplyr::left_join(data, pcoa_bac, by = "AccessionID")

# read in PCoA-Coordinates: Protists & merge with data
pcoa_prot <- read.csv("PCoA_Coordinates_Protists.csv", stringsAsFactors = FALSE)
colnames(pcoa_prot) <- c("PCoA1_Protists", "PCoA2_Protists", "AccessionID")
pcoa_prot$AccessionID <- as.character(pcoa_prot$AccessionID)
data <- dplyr::left_join(data, pcoa_prot, by="AccessionID")

# read in PCoA-Coordinates: Fungi & merge with data
pcoa_fungi <- read.csv("PCoA_Coordinates_Fungi.csv", stringsAsFactors = FALSE)
colnames(pcoa_fungi) <- c("PCoA1_Fungi", "PCoA2_Fungi", "AccessionID")
pcoa_fungi$AccessionID <- as.character(pcoa_fungi$AccessionID)
data <- dplyr::left_join(data, pcoa_fungi, by="AccessionID")

# read in PCoA-Coordinates: Metazoa & merge with data
pcoa_meta <- read.csv("PCoA_Coordinates_Metazoa.csv", stringsAsFactors = FALSE)
colnames(pcoa_meta) <- c("PCoA1_Metazoa", "PCoA2_Metazoa", "AccessionID")
pcoa_meta$AccessionID <- as.character(pcoa_meta$AccessionID)
data <- dplyr::left_join(data, pcoa_meta, by="AccessionID")

prepare_permanova <- function(microbial_community, plant = NULL) {
  
  # filter for Microbial Community (on which variable function is run)
  subset_df <- data %>% filter(Microbial_Community == microbial_community)
  if (!is.null(plant)) subset_df <- subset_df %>% filter(PLANT == plant)    # option for plant specific PERMANOVA
  
  # transform dates into seasons
  subset_df <- subset_df %>%
    mutate(COLLECTION_DATE = as.Date(COLLECTION_DATE),
           SEASON = case_when(
             month(COLLECTION_DATE) %in% c(12,1,2)  ~ "Winter",
             month(COLLECTION_DATE) %in% c(3,4,5)   ~ "Spring",
             month(COLLECTION_DATE) %in% c(6,7,8)   ~ "Summer",
             month(COLLECTION_DATE) %in% c(9,10,11) ~ "Fall",
             TRUE                                   ~ "Unknown"))
  
  # aggregate data --> sum Read counts per Genus
  wide_df <- subset_df |>
    group_by(AccessionID, Genus) |>
    summarise(TotalReads = sum(NumberOfReads), .groups = "drop") |>
    pivot_wider(names_from = Genus, values_from = TotalReads,
                values_fill = 0) |>
    column_to_rownames("AccessionID")
  
  # normalize read counts (will be used as base table for bray curtis calculation)
  norm_df <- sweep(wide_df, 1, rowSums(wide_df), "/")
  
  # reduce data to only the relevant columns (for the variance explaining factors)
  meta_df <- subset_df %>%
    distinct(AccessionID, LATITUDE, PLANT, SEASON,
             PCoA1_Protists, PCoA1_Fungi, PCoA1_Metazoa, PCoA1_Bacteria)
  
  # match AccessionID from base table and explaining factors table
  common_ids <- intersect(rownames(norm_df), meta_df$AccessionID)
  list(
    norm_data = norm_df[common_ids, , drop = FALSE],
    metadata  = meta_df %>% filter(AccessionID %in% common_ids) %>%
      column_to_rownames("AccessionID")
  )
}

# run Permanova via adonis 2 "by terms"; used factor can be sorted for the most fitting r^2 value order manually

# PERMANOVA: Bacteria
res_bac <- prepare_permanova("Bacteria")
bac_norm <- res_bac$norm_data
meta_bac <- res_bac$metadata

res_permanova_bac <- adonis2(
  bac_norm ~ LATITUDE + PLANT + SEASON + PCoA1_Fungi + PCoA1_Protists + PCoA1_Metazoa ,
  data         = meta_bac,
  permutations = 999,
  method       = "bray",
  by           = "terms",
  na.action    = "na.exclude"
)
res_permanova_bac

# PERMANOVA: Metazoa
res_metazoa <- prepare_permanova("Metazoa")
meta_norm <- res_metazoa$norm_data
meta_meta <- res_metazoa$metadata

res_permanova_metazoa <- adonis2(
  meta_norm ~ LATITUDE + PLANT + SEASON + PCoA1_Protists + PCoA1_Fungi + PCoA1_Bacteria ,
  data = meta_meta,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_metazoa

# PERMANOVA: Protists
res_prot <- prepare_permanova("Protists")
prot_norm <- res_prot$norm_data
meta_prot <- res_prot$metadata

res_permanova_prot <- adonis2(
  prot_norm ~ LATITUDE + PLANT + SEASON + PCoA1_Bacteria + PCoA1_Metazoa + PCoA1_Fungi ,
  data = meta_prot,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_prot

# PERMANOVA: Fungi
res_fungi <- prepare_permanova("Fungi")
fungi_norm <- res_fungi$norm_data
meta_fungi <- res_fungi$metadata

res_permanova_fungi <- adonis2(
  fungi_norm ~ LATITUDE + PLANT + SEASON + PCoA1_Bacteria + PCoA1_Protists + PCoA1_Metazoa ,
  data = meta_fungi,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_fungi

# save Results in Excel file 
# function to transform the PERMANOVA results into a data frame
extract_permanova <- function(x,
                              stars_breaks = c(0.001, 0.01, 0.05, 0.1),
                              stars_labels = c("***","**","*",".","")) {
  df <- as.data.frame(x)
  df$Term <- rownames(df); rownames(df) <- NULL
  df <- df[, c("Term","Df","SumOfSqs","R2","F","Pr(>F)")]
  pvals <- df[["Pr(>F)"]]
  df$Signif <- cut(pvals,
                   breaks = c(-Inf, stars_breaks, Inf),
                   labels = stars_labels,
                   right  = TRUE)  
  df
}

# run function to extract PERMANOVA results
bac_tab   <- extract_permanova(res_permanova_bac)
meta_tab  <- extract_permanova(res_permanova_metazoa)
prot_tab  <- extract_permanova(res_permanova_prot)
fungi_tab <- extract_permanova(res_permanova_fungi)

# save results into one Excel file --> each microbial Community gets its own sheet
write_xlsx(
  list(
    Bacteria = bac_tab,
    Metazoa  = meta_tab,
    Protists = prot_tab,
    Fungi    = fungi_tab
  ),
  path = "PERMANOVA_results.xlsx"
)


# Run Plant-specific PERMANOVAS:

# PERMANOVA: Bacteria
res_bac <- prepare_permanova("Bacteria", plant = "Copenhagen_RL") # change for the to be analyzed plant
bac_norm <- res_bac$norm_data
meta_bac <- res_bac$metadata

res_permanova_bac <- adonis2(
  bac_norm ~ SEASON + PCoA1_Fungi + PCoA1_Protists + PCoA1_Metazoa ,
  data         = meta_bac,
  permutations = 999,
  method       = "bray",
  by           = "terms",
  na.action    = "na.exclude"
)
res_permanova_bac

# PERMANOVA: Metazoa
res_metazoa <- prepare_permanova("Metazoa", plant = "Copenhagen_RL") # change for the to be analyzed plant
meta_norm <- res_metazoa$norm_data
meta_meta <- res_metazoa$metadata

res_permanova_metazoa <- adonis2(
  meta_norm ~ SEASON + PCoA1_Bacteria + PCoA1_Protists + PCoA1_Fungi ,
  data = meta_meta,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_metazoa

# PERMANOVA: Protists
res_prot <- prepare_permanova("Protists", plant = "Copenhagen_RL") # change for the to be analyzed plant
prot_norm <- res_prot$norm_data
meta_prot <- res_prot$metadata

res_permanova_prot <- adonis2(
  prot_norm ~ SEASON + PCoA1_Bacteria + PCoA1_Metazoa + PCoA1_Fungi ,
  data = meta_prot,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_prot

# PERMANOVA: Fungi
res_fungi <- prepare_permanova("Fungi", plant = "Copenhagen_RL") # change for the to be analyzed plant
fungi_norm <- res_fungi$norm_data
meta_fungi <- res_fungi$metadata

res_permanova_fungi <- adonis2(
  fungi_norm ~  PCoA1_Bacteria + SEASON + PCoA1_Metazoa + PCoA1_Protists ,
  data = meta_fungi,
  permutations = 999,
  method = "bray",
  by = "terms",
  na.action = "na.exclude"
)
res_permanova_fungi

# Results will be typed in manually in an Excel sheet, since for each Microbial Community - Plant combination the Term/Factor order has be set indivdually for the optimal R2 order
