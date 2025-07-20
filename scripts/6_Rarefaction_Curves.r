# Author: Niklas Nett
# Created: 2025-01-24
# Last updated: 2025-07-15

# Purpose: Generate rarefaction curves to assess sequencing depth and genus-level richness across samples.
#          Each curve shows the increase in observed genera with read depth per sample.
#          Curves are grouped by plant, allowing visual comparison of microbial richness saturation.
#          Option to create Rarefraction Curve for only eukaryotes or prokaryotes
# Input:   - filtered_combined_table_PR2_and_SILVA.csv (genus-level merged count table with metadata)
# Output:  - Rarefaction_Curves.svg   

# Load packages
library(dplyr)
library(tidyr)
library(vegan)
library(ggplot2)

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

# define colors
color_palette <- c(
    "Copenhagen_RL" = "#00BFC4",
    "Copenhagen_RD" = "#00BA38",
    "Copenhagen_RA" = "#7CAE00",
    "Rotterdam"     = "#C77CFF",
    "Budapest"      = "#F564E3",
    "Bologna"       = "#F8766D",
    "Rome"          = "#619CFF"
  )

# extract data from each sample & plant combination (for later joining)
plant_info <- data %>%
  select(AccessionID, PLANT) %>%
  distinct()  
data_filtered <- data[, c("AccessionID", "Genus", "NumberOfReads")]

# For Rarefraction Curve for ONLY Pro- or Eukaryotes:
# data_prokaryotes <- data %>%
# filter(Superdomain == "Prokaryote")
# data_filtered <- data_prokaryotes[, c("AccessionID", "Genus", "NumberOfReads")]
# or
# data_eukaryotes <- data %>%
# filter(Superdomain == "Eukaryote")
# data_filtered <- data_eukaryotes[, c("AccessionID", "Genus", "NumberOfReads")]

# Prepare data: group and aggregate data (since we have duplicates --> multiple groups of same Genus within same AccessionID)
data_aggregated <- data_filtered %>%
  group_by(AccessionID, Genus) %>% # group all Genus with each AccessionID
  summarise(NumberOfReads = sum(NumberOfReads), .groups = "drop") # aggregate NumberofReads for same Genus within same sample

# transform data into wide format --> Rows=AccessionIDs; columns=Genera; cell values = NumberOfReads
data_wide <- pivot_wider(
  data_aggregated,
  names_from = Genus,
  values_from = NumberOfReads,
  values_fill = 0 # Replace missing values with 0
)

# Convert to regular dataframe (for compatibility with other functions; ensures data consists of only numeric values)
data_wide <- as.data.frame(data_wide)

# define row name
# from:
#       AccessionID GenusA GenusB GenusC
# 1     Sample1     10      0      5
# 2     Sample2      0     15      7
# 3     Sample3      3      2      0
# to: 
#            AccessionID GenusA GenusB GenusC
# Sample1       Sample1     10      0      5
# Sample2       Sample2      0     15      7
# Sample3       Sample3      3      2      0
rownames(data_wide) <- data_wide$AccessionID

# remove AccessionID column (since they are also saved in the row names)
# finally:
#           GenusA GenusB GenusC
#  Sample1     10      0      5
#  Sample2      0     15      7
#  Sample3      3      2      0
data_wide$AccessionID <- NULL

# short overview --> check if everything worked (if script is activated row by row)
summary(data_wide)

# Perform rarefaction analysis (show species richness across samples) --> to get idea if sequencing depth was enough to show diversity
# step = 100: data analyzed in 100 reads per step
# label = FALSE: no label directly in plot
rare_curves <- rarecurve(as.matrix(data_wide), step = 100, label = FALSE)

# Assign each line in  plot to its corresponding AccessionID
names(rare_curves) <- rownames(data_wide)

# transform rarefaction data into data frame --> important for plotting
rare_data <- do.call(rbind, lapply(names(rare_curves), function(sample) { #names() = gives out names of the elements of the rare_curves data frame/table/list; then each is counted as the variable "sample"
  data.frame(
    Sample = sample,
    Reads = attr(rare_curves[[sample]], "Subsample"), #attr = Attribute of rare_curves(sample) (subsample: name given from rarefraction function)
    Species = rare_curves[[sample]]        # number of Genera per sample are taken from the rare_curve function/list for each 100 Read step
  )
}))

# Plant-Information zu rare_data hinzufügen
rare_data <- rare_data %>%
  left_join(plant_info, by = c("Sample" = "AccessionID"))

# Start Plotting:

# pre-settings for plot
y_scale_factor <- 1.5 # scaling for cleaner vizualisation
rare_data$Species <- rare_data$Species * y_scale_factor

# define multiple line types (again to makes it easier to differ between all the curves)
valid_linetypes <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")
linetype_values <- rep(valid_linetypes, length.out = nrow(data_wide))  # needs to be repeated since we have more curves than availbe line types

# create final ggplot
ggplot(rare_data, aes(x = Reads, y = Species, linetype = PLANT, color = PLANT, group = Sample)) +
  geom_line(size = 0.5, alpha = 0.7) + # set width of lines
  scale_color_manual(values = color_palette) +
  scale_linetype_manual(
    values = linetype_values,
    name = "Plant"
  ) +
guides(
  colour = guide_legend(          
    title        = "Plant",
    title.position = "top",
    nrow         = 2,
    byrow        = TRUE,
    override.aes = list(linewidth = 1.4), 
    keywidth     = unit(0.8, "cm")          
  ),
  linetype =  guide_legend(          
    title        = "Plant",
    title.position = "top",
    nrow         = 2,
    byrow        = TRUE,   
    keywidth     = unit(0.8, "cm")          
  )             
) +
  labs(
    title = NULL,
    x = "Number of Reads",
    y = "Number of Genera"
  ) +
   theme_minimal(base_family = "Helvetica Neue") +
  theme(
    legend.position = "bottom",  
    legend.title = element_text(size = 16, face = "bold"), 
    legend.text = element_text(size = 14),  
    legend.key.size = unit(0.4, "cm"), 
    legend.spacing.x = unit(0.3, 'cm'),  
    legend.box.margin    = margin(t = 20, r = 0, b = 0, l = 0),
    plot.title = element_text(size = 14, face = "bold", margin = margin(b = 32)),
    plot.title.position = "plot",  
    axis.text = element_text(size = 9),
    plot.margin = margin(t = 20, r = 20, b = 20, l = 20), 
    axis.title.x = element_text(size = 15, margin = margin(t = 16)), 
    axis.title.y = element_text(size = 15, margin = margin(r = 16))  
  )


# Save plot as Svg
ggsave(
  filename = "Rarefaction_Curves.svg", 
  plot = last_plot(),                            
  device = "svg",                                
  width = 12,                                    
  height = 8,                                    
  dpi = 300                                      
)