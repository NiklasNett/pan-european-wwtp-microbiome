# Author: Niklas Nett
# Created: 2025-06-09
# Last updated: 2025-07-20

# Purpose: Analyze the abundance of a specific genus within one selected microbial community WWTP. 
#          Calculates mean abundance, standard deviation, and number of detections across samples.
# Input:   - Merged_Shannon_RelAbund_Table.xlsx  
# Output:  - Console output with summary statistics (mean %, standard deviation, number of detections)

# Load packages
library(readxl)   
library(dplyr) 

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# settings that can be changed; according to what should be analyzed
sheet <- "Protists"
plant_name <- c("Copenhagen_RD")               
taxa_col   <- "Rhogostoma"     

# Read input file (merged table with shannon and relative abundance results)
df <- read_excel("Merged_Shannon_RelAbund_Table.xlsx", sheet = sheet) # here change sheet to the microbial community that needs to be analyzed

# filter out to be analyzed plant
df_plant <- df %>%
  filter(tolower(PLANT) %in% tolower(plant_name))

# filter out to be analyzed taxon
values <- df_plant[[taxa_col]]

# calculate mean, standard deviation and how many times this taxon appears (in that plant in different samples)
avg <- mean(values)
sdv <- sd(values)          
n   <- length(values)

# Output:
cat("Microbial Community:", sheet, "\n")
cat("Plant:", plant_name, "\n")
cat("Taxon:", taxa_col, "\n")
cat("Times of Appearences:", n, "\n")
cat(sprintf("Average (%%): %.2f\n", avg)) #sprintf = formated string; %% creates normal % in formated strings; %.2f prints out 2 decimals
cat(sprintf("Std. deviation  : %.2f\n", sdv))