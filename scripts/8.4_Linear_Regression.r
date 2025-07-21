# Author: Niklas Nett
# Created: 2025-07-21
# Last updated: 2025-07-21

# Purpose: Test whether the abundance of a selected taxon follows a significant latitudinal gradient, 
#          using linear regression on plant order (north-to-south).
# Input:   - Merged_Shannon_RelAbund_Table.xlsx   
# Output:  - Console output with R² and p-value of the regression

library(readxl)
library(dplyr)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# settings that can be changed; according to what should be analyzed
sheet      <- "Bacteria"           
taxa_col   <- "Trichococcus"    

# Read input file (merged table with shannon and relative abundance results)
df <- read_excel("Merged_Shannon_RelAbund_Table.xlsx", sheet = sheet)  # here changes sheet to the microbial community that needs to be analyzed

# set order of plants (north to south)
plant_order <- c("Copenhagen_RL", "Copenhagen_RD", "Copenhagen_RA", "Rotterdam", "Budapest", "Bologna", "Rome")

# Set plant order explicitly and assign numeric ranks (prevents default alphabetical ranking)
df <- df %>%
  mutate(PLANT = factor(PLANT, levels = plant_order),
         rank  = as.integer(PLANT),
         taxa_relative_data = .data[[taxa_col]])

# Perform linear regression and save R² and p value
lin_mod <- lm(taxa_relative_data ~ rank, data = df)
r2  <- summary(lin_mod)$r.squared
p_value <- summary(lin_mod)$coefficients["rank", "Pr(>|t|)"]

# Console-Output for R² and p value
cat("R² :", r2, "\n")
cat("p  :", p_value, "\n")
