# Author: Niklas Nett
# Created: 2025-02-19
# Last updated: 2025-07-20

# Purpose: Perform Principal Coordinates Analysis (PCoA) based on genus-level relative abundances to visualize microbial community differences across samples and WWTPs.
#          Includes envfit arrows for sample metadata (latitude) and the 10 most abundant genera.
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
# Output:  - PCoA plots per microbial community (.svg)
#          - PCoA coordinate tables for PERMANOVA (.csv)

# Load packages
library(vegan)
library(ggplot2)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggnewscale)
library(tibble) 
library(ggrepel)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# Read input file (merged table)
data <- read.csv("filtered_combined_table_PR2_and_SILVA.csv", header = TRUE)

# set order of plants (north to south)
plant_order <- c("Copenhagen_RL", "Copenhagen_RD", "Copenhagen_RA", "Rotterdam", "Budapest", "Bologna", "Rome")

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

# Split data for each microbial community
protist_data     <- data %>% filter(Microbial_Community == "Protists")
fungi_data        <- data %>% filter(Microbial_Community == "Fungi")
metazoa_data     <- data %>% filter(Microbial_Community == "Metazoa")
bacteria_data     <- data %>% filter(Microbial_Community == "Bacteria")

# Create PCoA function
create_pcoa_plots <- function(df, microbial_community) {
  # Prepare data: group and aggregation
  aggregated_table <- df %>%
    group_by(AccessionID, Genus) %>%
    summarise(NumberOfReads = sum(NumberOfReads), .groups = "drop") %>%
    pivot_wider(names_from = Genus, values_from = NumberOfReads, values_fill = 0) %>%
    column_to_rownames("AccessionID")
  
  # Normalize counts to obtain relative abundances per sample
  normalized_counts <- sweep(aggregated_table, 1, rowSums(aggregated_table), "/")
  
  # Calculate Bray-Curtis distance matrix
  bray_curtis <- vegdist(normalized_counts, method = "bray")
  
  # Perform Principal Coordinates Analysis (PCoA)
  PCoA <- cmdscale(bray_curtis, k = 2, eig = TRUE)
  PCoA$points[,1] <- -PCoA$points[,1]
  PCoA$points[,2] <- -PCoA$points[,2]
  
  # Prepare data for ggplot
  coordinates <- as.data.frame(PCoA$points)
  colnames(coordinates) <- c("PCoA1", "PCoA2")
  coordinates$AccessionID <- rownames(coordinates)
  
  # Save coordinates as CSV for Permanova
  coords_outfile <- paste0("PCoA_Coordinates_", microbial_community, ".csv")
  write.csv(coordinates, coords_outfile, row.names = FALSE)
  
  # Calculate percentage variance explained
  var_ex <- 100 * (PCoA$eig / sum(PCoA$eig))[1:2]
  x.label <- paste0("PCoA1 [", round(var_ex[1], 2), "%]")
  y.label <- paste0("PCoA2 [", round(var_ex[2], 2), "%]")
  
  # Merge coordinates with Metadata
  plot_data <- coordinates %>%
    left_join(df %>% select(AccessionID, PLANT, COLLECTION_DATE, LATITUDE) %>% distinct(), 
              by = "AccessionID") %>%
    mutate(COLLECTION_DATE = as.Date(COLLECTION_DATE)) %>%
    mutate(SEASON = case_when(
      month(COLLECTION_DATE) %in% c(12, 1, 2)  ~ "Winter (1.12-28/29.2)",
      month(COLLECTION_DATE) %in% c(3, 4, 5)    ~ "Spring (1.3-31.5)",
      month(COLLECTION_DATE) %in% c(6, 7, 8)     ~ "Summer (1.6-31.8)",
      month(COLLECTION_DATE) %in% c(9, 10, 11) ~ "Fall (1.9-30.11)"
    ))
  
  # Define factors and colors
  plot_data$PLANT <- factor(plot_data$PLANT, levels = plant_order)
  
  season_colors <- c(
    "Winter (1.12-28/29.2)"  = "#64C2FF",
    "Spring (1.3-31.5)" = "#EB8BCA",
    "Summer (1.6-31.8)"   = "#78E300",
    "Fall (1.9-30.11)"  = "#FF9F45"
  )
  
  plant_colors <- c(
    "Copenhagen_RL" = "#00BFC4",
    "Copenhagen_RD" = "#00BA38",
    "Copenhagen_RA" = "#7CAE00",
    "Rotterdam"     = "#C77CFF",
    "Budapest"      = "#F564E3",
    "Bologna"       = "#F8766D",
    "Rome"          = "#619CFF"
  )
  
  # Create plot
  p <- ggplot(plot_data, aes(x = PCoA1, y = PCoA2)) +
    stat_ellipse(aes(group = SEASON, fill = SEASON), 
                 geom = "polygon", 
                 alpha = 0.1, color = NA, 
                 type = "t", 
                 level = 0.95) +
    scale_fill_manual(values = season_colors, name = "Season") +
    geom_point(aes(
      color = SEASON, 
      shape = PLANT), size = 1, 
      alpha = 0.7, stroke = 1) +
    scale_color_manual(values = season_colors, name = "Season") +
    scale_shape_manual(values = c(
      "Rome" = 8, 
      "Budapest" = 17, 
      "Copenhagen_RA" = 15, "Copenhagen_RL" = 16, 
      "Copenhagen_RD" = 18, 
      "Rotterdam" = 4, 
      "Bologna" = 3), 
      name = "Plant") +
    ggnewscale::new_scale_color() +
    stat_ellipse(aes(
      color = PLANT, 
      group = PLANT), 
      type = "t", 
      level = 0.95, 
      linetype = 2, 
      size = 0.7, 
      show.legend = FALSE) +
    scale_color_manual(values = plant_colors, guide = "none") +
    geom_point(aes(
      color = PLANT, 
      shape = PLANT), 
      size = 0, 
      alpha = 0, 
      stroke = 0, 
      show.legend = TRUE) +
    scale_color_manual(values = plant_colors, name = "Plant", 
                       guide = guide_legend(override.aes = list(size = 1, alpha = 1, stroke = 1, color = unname(plant_colors), fill = unname(plant_colors)))) +
    labs(title = NULL, 
         x = x.label, y = y.label) +
    theme_minimal() +
    theme(plot.title = element_text(size = 23, face = "bold"), 
          axis.title.x = element_text(size = 20, margin = margin(t = 15)), 
          axis.title.y = element_text(size = 20, margin = margin(r = 15)), 
          axis.text = element_text(size = 18), 
          legend.position = "right",
          legend.title = element_text(face = "bold")
    )
  
  # Add Arrows from Metadata via envfit
  # first create ordination object for arrow orientation
  ord_obj <- ordiplot(PCoA$points, display = "sites", type = "n")
  
  # first add Latitude Arrow
  # select matching latitudes per sample
  env_data <- plot_data %>%
    select(AccessionID, LATITUDE) %>%
    distinct() %>%
    slice(match(rownames(PCoA$points), AccessionID))
  
  env_data_latitude <- data.frame(LATITUDE = env_data$LATITUDE)
  # calculate arrow ordination
  envfit_meta <- envfit(ord_obj, env_data_latitude, permutations = 999)
  scores_meta <- as.data.frame(scores(envfit_meta, display = "vectors"))
  if (nrow(scores_meta) > 0) {                            # plot arrows into plot (if actual values could be calculated)
    mult_meta <- ordiArrowMul(envfit_meta)
    scores_meta$PCoA1 <- scores_meta$Dim1 * mult_meta
    scores_meta$PCoA2 <- scores_meta$Dim2 * mult_meta
    p <- p +
      geom_segment(data = scores_meta, aes(
        x = 0, 
        y = 0, 
        xend = PCoA1, 
        yend = PCoA2), 
        arrow = arrow(length = unit(0.2,"cm")), color = "red", 
        size = 0.8, 
        alpha = 0.7) +
      geom_text(data = scores_meta, aes(
        x = PCoA1, 
        y = PCoA2, 
        label = rownames(scores_meta)), 
        color = "red", size = 4, vjust = -0.5)
  }
  
  # next add Arrows of top 10 taxa of same Microbial Community
  genus_sums   <- colSums(aggregated_table)
  top10_genera <- names(sort(genus_sums, decreasing = TRUE))[1:10] # find out 10 most dominant taxa 
  # calculate arrow ordination
  envfit_taxa <- envfit(ord_obj, normalized_counts[, top10_genera], permutations = 999)
  scores_taxa <- as.data.frame(scores(envfit_taxa, display = "vectors"))
  if (nrow(scores_taxa) > 0) {                           # plot arrows into plot (if actual values could be calculated)
    mult_taxa <- ordiArrowMul(envfit_taxa)
    scores_taxa$PCoA1 <- scores_taxa$Dim1 * mult_taxa
    scores_taxa$PCoA2 <- scores_taxa$Dim2 * mult_taxa
    scores_taxa$Genus <- rownames(scores_taxa)
    p <- p +
      geom_segment(data = scores_taxa, aes(
        x = 0, 
        y = 0, 
        xend = PCoA1, 
        yend = PCoA2), 
        arrow = arrow(length = unit(0.2,"cm")), 
        color = "black", 
        alpha = 0.6) +
      geom_text_repel(data = scores_taxa, aes(
        x = PCoA1, 
        y = PCoA2, 
        label = Genus), 
        color = "black", 
        size = 4, 
        fontface = "bold", 
        max.overlaps = 20, 
        box.padding = 0.4, 
        point.padding = 0.3, 
        min.segment.length = 0, 
        segment.color = "grey50", 
        alpha = 0.7)
  }
  # Save the plot
  ggsave(paste0("PCoA_Plot_", microbial_community, ".svg"), p, width = 9, height = 6, device = "svg")
}

# Run PCoA function for each Microbial Community
create_pcoa_plots(protist_data, "Protists")
create_pcoa_plots(fungi_data, "Fungi")
create_pcoa_plots(metazoa_data, "Metazoa")
create_pcoa_plots(bacteria_data, "Bacteria")