# Author: Niklas Nett
# Created: 2025-03-17
# Last updated: 2025-07-20

# Purpose: Generate faceted stacked bar plots for relative abundance of the 10 most abundant genera per microbial community (Bacteria, Protists, Fungi, Metazoa) for each WWTPs. 
#          Abundance data is saved and merged with precomputed Shannon diversity indices for further analysis.
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
#          - ShannonTable_<Community>.csv
# Output:  - Stacked_barplot_<Community>.svg                 
#          - Merged_Shannon_RelAbund_Table.xlsx (uploaded as Supplementary_Table_S3.xlsx)             

# Load packages
library(tidyr)
library(ggplot2)
library(writexl)
library(dplyr)
library(readr) 

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# Read input file (merged table)
data <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE, stringsAsFactors = FALSE)

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

# set order of plants (north to south)
plant_order <- c("Copenhagen_RL", "Copenhagen_RD", "Copenhagen_RA", "Rotterdam", "Budapest", "Bologna", "Rome")

# create stacked bar plot function
create_barplot <- function(df, microbial_community) {
  
  # Transform COLLECTION_DATE in Dates & aggregate NumberofReads of Genera per AccessionID
  aggregated <-  df %>%
    mutate(Date = as.Date(COLLECTION_DATE)) %>%
    group_by(AccessionID, PLANT, Genus, Date) %>%   
    summarise(TotalReads = sum(NumberOfReads), .groups = "drop")
  
  # sum total reads per samples (AccessionID) --> for calculating relative values
  sample_totals <- aggregated %>%
    group_by(AccessionID) %>%
    summarise(SampleSum = sum(TotalReads), .groups = "drop")
  
  # calculate relative values
  rel_data <- aggregated %>%
    left_join(sample_totals, by = "AccessionID") %>%
    mutate(RelAbundance = TotalReads / SampleSum)
  
  # Filter out top 10 (most dominant) genera; group Genus and TotalReads numbers, order descending and cut of top 10
  genus_totals <- aggregated %>%
    group_by(Genus) %>%
    summarise(Total = sum(TotalReads), .groups = "drop") %>%
    arrange(desc(Total))
  
  top10 <- genus_totals %>%
    slice_head(n = 10) %>%
    pull(Genus)
  
  # bin everything else than the top 10 genera into "Others"
  rel_data <- rel_data %>%
    mutate(Genus_merged = ifelse(Genus %in% top10, Genus, "Others"))
  
  #by previous ifelse code replaced "Others" duplicates were created --> are redundant and will be summed together
  rel_merged <- rel_data %>%
    group_by(AccessionID, PLANT, Date, Genus_merged, SampleSum) %>%
    summarise(TotalReads = sum(TotalReads), .groups = "drop") %>%
    mutate(RelAbundance = TotalReads / SampleSum)
  
  # sort dates on x-axis, chronologically, each sample =  one bar
  rel_merged <- rel_merged %>% 
    mutate(sort_str = factor(format(Date, "%Y-%m-%d"),
                             levels = sort(unique(format(Date, "%Y-%m-%d")))))
  
  
  # set order of taxa --> first top 10, then Others at end
  main     <- sort(top10)
  final_ord  <- c(main, "Others")
  
  # define colors top 10
  main_cols <- c(
    "#66C2A5", 
    "#FC8D62", 
    "#8DA0CB",  
    "#E78AC3", 
    "#B373D8",  
    "#8291F6",  
    "#E5C494", 
    "#B3B3B3",
    "#F564E3", 
    "#7CAE00",  
    "#00BFC4", 
    "#619CFF",  
    "#00BA38",  
    "#C77CFF",
    "#F8766D"
  )
  color_map  <- setNames(main_cols, main) # top 10 taxa are linked with main colors
  color_map  <- c(color_map, "Others" = "black") # Others is set as black
  color_map  <- color_map[final_ord]   
  
  # define/sort relative values in right order for plants --> so facette shows first most northern and most southern last
  rel_merged$PLANT <- factor(rel_merged$PLANT, 
                             levels = plant_order)
  
  # define/sort relative values in right order for taxa --> so legend also fallows color-map
  rel_merged$Genus_merged <- factor(rel_merged$Genus_merged, levels = final_ord)
  
  # create facette plot
  p <- ggplot(rel_merged, aes(
    x    = sort_str,
    y    = RelAbundance,
    fill = Genus_merged
  )) +
    geom_col(position="stack", width=0.8) +
    facet_wrap(~PLANT, nrow=1, scales="free_x") +
    scale_fill_manual(values=color_map,
                      name=paste(microbial_community, "- Genera"),
                      breaks=final_ord) +
    scale_x_discrete(
      breaks = levels(rel_merged$sort_str),
      labels = rep("", length(levels(rel_merged$sort_str)))           
    ) +
    labs(
      title = NULL,
      x     = NULL,
      y     = "Relative Abundance"
    ) +
    guides(
      fill = guide_legend(
        title.position = "top",
        nrow           = 2,      
        byrow          = TRUE
      )
    ) +
    theme_minimal(base_family = "Helvetica Neue") +
    theme(
      strip.text       = element_text(face = "bold", size = 35),
      strip.background = element_rect(fill = "gray80", color = NA),
      axis.line.x       = element_line(colour = "black", linewidth = 0.4),
      axis.ticks.x      = element_line(colour = "black", linewidth = 0.4),
      axis.ticks.length = unit(6, "pt"), 
      axis.text.x       = element_blank(),
      axis.text.y      = element_text(size = 30),
      axis.title.x     = element_text(size = 30),
      axis.title.y     = element_text(size = 30, margin = margin(r = 20)),
      legend.position  = "bottom",   
      legend.title     = element_text(size = 45, face = "bold", margin = margin(b = 10)),
      legend.text      = element_text(size = 45, margin = margin(l = 17, r = 20)),   
      legend.margin      = margin(t = 30),
      legend.key.size  = unit(2, "lines"),           
      panel.spacing.x = unit(2, "lines")
    )
  
  # save plot as SVG
  outfile <- paste0("Stacked_barplot_", microbial_community, ".svg")
  ggsave(outfile, p, width = 44, height = 6, dpi = 300, device = "svg")
  cat("Saved:", outfile, "\n")
  
  # also save values into data frame...
  wide <- rel_merged %>%
    mutate(RelPct = round(RelAbundance * 100, 2)) %>%               # tranform Relative Abundance values into percentages with two decimals
    select(AccessionID, PLANT, Date, Genus_merged, RelPct) %>%
    pivot_wider(names_from = Genus_merged,
                values_from = RelPct,
                values_fill = 0) %>%
    mutate(Date = format(Date, "%m-%d-%Y")) %>%
    relocate(all_of(top10), .after = Date) %>%                      # column order
    arrange(as.Date(Date, "%m-%d-%Y"))
  
  # ...and merge with shannon value tables (for further analysis)
  shan_path <- file.path(paste0("ShannonTable_", microbial_community, ".csv"))
  shan_df   <- readr::read_csv(shan_path, show_col_types = FALSE)
  
  merged_tbl <- shan_df %>%
    left_join(wide, by = c("AccessionID", "PLANT", "Date")) %>%
    mutate(PLANT = factor(PLANT, levels = plant_order)) %>%
    arrange(PLANT, as.Date(Date, "%m-%d-%Y"))
  
  list(plot = p, table = merged_tbl)
}

# run stacked bar plot function for each Microbial Community
fungi_data <- data %>% filter(Microbial_Community == "Fungi")
proti_data <- data %>% filter(Microbial_Community == "Protists")
metaz_data <- data %>% filter(Microbial_Community == "Metazoa")
bac_data <- data %>% filter(Microbial_Community == "Bacteria")

out <- list(
  Bacteria = create_barplot(bac_data,   "Bacteria"),
  Metazoa  = create_barplot(metaz_data, "Metazoa"),
  Protists = create_barplot(proti_data, "Protists"),
  Fungi    = create_barplot(fungi_data, "Fungi")
)

# save merged table as Excel file; since function was run by a list --> each Microbial community Table is now an individual sheet in the xlsx file
write_xlsx(
  lapply(out, `[[`, "table"),
  "Merged_Shannon_RelAbund_Table.xlsx"
)