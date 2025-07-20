# Author: Niklas Nett
# Created: 2025-01-23
# Last updated: 2025-07-15

# Purpose: Create summary tables that describe the microbial community composition (Bacteria, Archaea, Protists, Fungi, Metazoa) per WWTP and overall.
#          Output includes both raw read counts and relative proportions per microbial group.
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
# Output:  - Compound_table_reads_percentage.csv     → [%] of reads per microbial group per WWTP
#          - Compound_table_genera_percentage.csv    → [%] of genera per microbial group per WWTP
#          - Compound_table_reads_counts.csv         → Total read counts per microbial group per WWTP
#          - Compound_table_genera_counts.csv        → Number of unique genera per group per WWTP
#          (→ all four tables were combined and uploaded as Supplementary_Table_S2.xlsx)

# Load packages
library(dplyr)              

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# Read input file (merged table)
data <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE, stringsAsFactors = FALSE)

# rename plants
plant_renames <- c(
  "Rensningsanlaeg Damhusaaen"                 = "Copenhagen_RD",
  "Rensningsanlaeg Avedoere"                   = "Copenhagen_RA",
  "Rensningsanlaeg Lynetten"                   = "Copenhagen_RL",
  "Dokhaven"                                   = "Rotterdam",
  "ATO2 Wastewater Treatment Plant"            = "Rome",
  "Gruppo HERA"                                = "Bologna",
  "Budapesti Kozponti Szennyviztisztito Telep" = "Budapest"
)

# create compound-table function (to go through each Microbial Community)
create_compound_table <- function(data) {
  # data preparation
  # Create row names: Each row gets unique name based on its position and the corresponding genera
  rownames(data) <- paste(seq(nrow(data)), data$Genera, sep = "_")
  
  # extract NumberOfReads
  counts <- data$NumberOfReads
  
  # Calculate the number of reads for each Microbial_Community
  number_of_reads <- c(
    Bacteria = sum(counts[data$Microbial_Community == "Bacteria"]),
    Archaea  = sum(counts[data$Microbial_Community == "Archaea"]),
    Protists = sum(counts[data$Microbial_Community == "Protists"]),
    Fungi    = sum(counts[data$Microbial_Community == "Fungi"]),
    Metazoa  = sum(counts[data$Microbial_Community == "Metazoa"])
  )
  
  # Calculate Percentage share
  percentage_reads <- round(number_of_reads / sum(number_of_reads) * 100, 2)
  
  # Ensure sum of calculated reads per Microbial_Community matches sum of all NumberOfReads
  if (sum(number_of_reads) != sum(counts)) {
    stop("Number of reads must match summed counts")
  }
  
  # Calculate the Number of Genera
  number_of_Genera <- c(
    Bacteria = nrow(filter(data, Microbial_Community == "Bacteria")),
    Archaea  = nrow(filter(data, Microbial_Community == "Archaea")),
    Protists = nrow(filter(data, Microbial_Community == "Protists")),
    Fungi    = nrow(filter(data, Microbial_Community == "Fungi")),
    Metazoa  = nrow(filter(data, Microbial_Community == "Metazoa"))
  )
  
  # Calculate Percentage share
  percentage_Genera <- round(number_of_Genera / sum(number_of_Genera) * 100, 2)
  
  # Ensure sum of calculated Genera matches sum of all number of rows of NumberOfReads entries
  if (sum(number_of_Genera) != length(counts)) {
    stop("Number of Genera must match number of rows of counts data")
  }
  
  # Merge data frame directly
  table <- setNames(
    data.frame(
      cbind(
        number_of_reads,
        percentage_reads,
        number_of_Genera,
        percentage_Genera
      )
    ),
    c("Number of reads", "[%]", "Number of genera", "[%]")
  )
  
  return(table)
}

# create compound table for all Plants together
overall_table <- create_compound_table(data)
cat("\n--- Microbial Community Composition for overall data ---\n")
print(overall_table)

# create 4 data frames:
# reads_table: percentage share - number of reads per microbial community
# genera_table: percentage share - number of genera per microbial community
# reads_counts_table: number of reads per microbial community
# genera_counts_table: number of genera per microbial community
# Rownames extracted from overall_table --> are the Microbial Communities
reads_table  <- data.frame(row.names = rownames(overall_table))
genera_table <- data.frame(row.names = rownames(overall_table))
reads_counts_table   <- data.frame(row.names = rownames(overall_table))  
genera_counts_table  <- data.frame(row.names = rownames(overall_table))   


# for-loop, so compound-table function is run for each plant
for (plants in names(plant_renames)) {
  plant_data  <- data %>% filter(PLANT == plants) # filters out plants in count table (via the actual long name)
  plant_table <- create_compound_table(plant_data)
  
  # re-names the filtered out actual long plant names
  short_name <- plant_renames[[plants]]
  
  # extract columns (from function output) into created data frames
  reads_table[[short_name]]  <- plant_table[[2]]  
  genera_table[[short_name]] <- plant_table[[4]]  
  reads_counts_table[[short_name]]  <- plant_table[[1]]  
  genera_counts_table[[short_name]] <- plant_table[[3]]  
}

# add Overall column
reads_table[["Overall"]]  <- overall_table[[2]]  
genera_table[["Overall"]] <- overall_table[[4]] 
reads_counts_table[["Overall"]]   <- overall_table[[1]]   
genera_counts_table[["Overall"]]  <- overall_table[[3]] 

# set order from north (left) to south (right)
desired_order <- c(
  "Copenhagen_RL",
  "Copenhagen_RD",
  "Copenhagen_RA",
  "Rotterdam",
  "Budapest",
  "Bologna",
  "Rome",
  "Overall"
)

reads_table  <- reads_table[, desired_order]
genera_table <- genera_table[, desired_order]
reads_counts_table   <- reads_counts_table[, desired_order]   
genera_counts_table  <- genera_counts_table[, desired_order] 

# add "," in count data after every third number for improved readability
fmt_counts <- function(df) {
  data.frame(lapply(df, function(x) formatC(x, format = "d", big.mark = ",")),
             row.names = rownames(df), check.names = FALSE)
}
reads_counts_fmt   <- fmt_counts(reads_counts_table)
genera_counts_fmt  <- fmt_counts(genera_counts_table)

# Add "Microbial Community" as first column header and save as csv 
write.csv(cbind("Microbial Community" = rownames(reads_table),  reads_table),
          "Compound_table_reads_percentage.csv",  row.names = FALSE)

write.csv(cbind("Microbial Community" = rownames(genera_table), genera_table),
          "Compound_table_genera_percentage.csv", row.names = FALSE)

write.csv(cbind("Microbial Community" = rownames(reads_counts_fmt),  reads_counts_fmt),
          "Compound_table_reads_counts.csv",  row.names = FALSE)

write.csv(cbind("Microbial Community" = rownames(genera_counts_fmt), genera_counts_fmt),
          "Compound_table_genera_counts.csv", row.names = FALSE)
