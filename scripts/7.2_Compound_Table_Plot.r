# Author: Niklas Nett
# Created: 2025-04-02
# Last updated: 2025-06-11

# Purpose: Visualize the relative contribution of each microbial community (Bacteria, Archaea, Protists, Fungi, Metazoa) based on two metrics:
#          (1) Number of Reads per group and (2) Number of Genera per group.
#          Create a split-axis barplot to account for large differences in abundance.
#          Create a separate dummy plot to create a custom dual legend layout.
# Input:   - Compound_table_reads_percentage.csv     → [%] of reads per microbial group per WWTP
#          - Compound_table_genera_percentage.csv    → [%] of genera per microbial group per WWTP

# Output:  - Compound_Table_plot.svg        → Barplot with y-axis break for visualization
#          - Compound_Table_dummy_plot.svg  → Dummy plot with split legend for separate export

# Load packages
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggbreak)
library(ggnewscale)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# read in the compound tables with percentage values for Number of Genera and Number of Reads
reads_table  <- read.csv("Compound_table_reads_percentage.csv",  header = TRUE, row.names = 1, check.names = FALSE)
genera_table <- read.csv("Compound_table_genera_percentage.csv", header = TRUE, row.names = 1, check.names = FALSE)

# transpose tables (rows = Plants; Columns = Microbial communities (Bacteria/Archaea/…))
reads_df  <- as.data.frame(t(reads_table))
genera_df <- as.data.frame(t(genera_table))

# Add "Plant" column
reads_df$Plant  <- rownames(reads_df)
genera_df$Plant <- rownames(genera_df)

# bring into long format and labels everything
reads_long <- reads_df %>%
  pivot_longer(
    cols      = c("Bacteria", "Archaea", "Protists", "Fungi", "Metazoa"),
    names_to  = "Microbial_Community",
    values_to = "Percentage"
  ) %>%
  mutate(Type = "Reads")

genera_long <- genera_df %>%
  pivot_longer(
    cols      = c("Bacteria", "Archaea", "Protists", "Fungi", "Metazoa"),
    names_to  = "Microbial_Community",
    values_to = "Percentage"
  ) %>%
  mutate(Type = "Genera")

df_long <- bind_rows(reads_long, genera_long)

# delete "Overall" row
df_long <- df_long %>%
  filter(Plant != "Overall")

# order for each microbial community the fitting read value and genera percentages next to each other
# define name combination for ordering --> which Microbial_Community + "-" + which type (Read or Genera values)
df_long <- df_long %>%
  mutate(GroupType = interaction(Microbial_Community, Type, sep = "-"))

# set order
level_order <- c("Bacteria-Reads","Bacteria-Genera",
                 "Archaea-Reads","Archaea-Genera",
                 "Fungi-Reads","Fungi-Genera",
                 "Protists-Reads","Protists-Genera",
                 "Metazoa-Reads","Metazoa-Genera")
df_long$GroupType <- factor(df_long$GroupType, levels = level_order)

# set order --> later from north (left) to south (right)
desired_order <- c("Copenhagen_RL",
                   "Copenhagen_RD",
                   "Copenhagen_RA",
                   "Rotterdam",
                   "Budapest",
                   "Bologna",
                   "Rome")
df_long$Plant <- factor(df_long$Plant, levels = desired_order)

# define colors
colors <- c(
  "Bacteria-Reads"    = "#377EB8",  
  "Bacteria-Genera"   = "#9ECAE1",  
  
  "Archaea-Reads"     = "#E41A1C", 
  "Archaea-Genera"    = "#FC9272",  
  
  "Fungi-Reads"       = "#984EA3", 
  "Fungi-Genera"      = "#DDA0DD",  
  
  "Protists-Reads"    = "#4DAF4A",  
  "Protists-Genera"   = "#A1D99B", 
  
  "Metazoa-Reads"     = "#FF7F00",  
  "Metazoa-Genera"    = "#FDBF6F"   
)

# create basis ggplot
p <- ggplot(df_long, aes(x = Plant, y = Percentage, fill = GroupType)) +
  geom_col(                                    # column settings
    position = position_dodge(width = 0.8),  
    width    = 0.7                           
  ) +
  theme_bw(base_size = 14, base_family = "Helvetica") + 
  theme(
    axis.text.x   = element_text(angle = 45, hjust = 1),
    legend.position = "right",
    panel.border  = element_blank()          
  ) +
  scale_fill_manual(values = colors) +  
  labs(
    x    = NULL,
    y    = "Relative Abundance [%]",
    fill = NULL
  ) 

# since bacteria values are way higher than values of other microbial communities --> will create a breake within the plot axis
p_broken <- p +
  scale_y_cut(
    breaks = c(4, 91),   # define between which values break should occur (4% to 91%)
    scales = c(1, 2),    
    space  = 0.05
  ) +
  expand_limits(y = 100)   # define maximum

# want to have legend that is separated into 2 groups --> one titling Reads and then one with Genera; both will have just the microbial Community name stated in it --> doesnt work with so far layout --> therefor extra plot will be created just for legend; which will then bve cropped out and pasted into basis plot

# Goal: Create a legend that separates Reads and Genera:
# - Each group ("Number of Reads" and "Number of Genera") should have its own title
# - Within each group only the microbial community names should be listed (e.g. Bacteria, Archaea, etc.)
# --> This layout cannot be achieved directly in ggplot2 --> separate dummy plot is created just to generate the custom legend
# --> custom legend will be manually cropped and  added to the main plot later

# dummy plot preparation
df_long <- df_long %>% 
  mutate(MicrobialGroup = Microbial_Community)  

reads_data  <- df_long %>% filter(Type == "Reads")
genera_data <- df_long %>% filter(Type == "Genera")

# create dummy plot
p_two_legends <- ggplot() +
  # first layer for Reads legend
  geom_col(
    data     = reads_data,
    aes(x = Plant, y = Percentage, fill = MicrobialGroup),
    position = position_dodge2(width = 0.9, preserve = "single"),
    width    = 0.4
  ) +
  scale_fill_manual(
    name   = "Number of Reads",
    values = c(
      "Bacteria" = "#377EB8",
      "Archaea"  = "#E41A1C",
      "Fungi"    = "#984EA3",
      "Protists" = "#4DAF4A",
      "Metazoa"  = "#FF7F00"
    ),
    guide = guide_legend(order = 1)
  ) +
  new_scale_fill() +

  # second layer for Genera legend
  geom_col(
    data     = genera_data,
    aes(x = Plant, y = Percentage, fill = MicrobialGroup),
    position = position_dodge2(width = 0.9, preserve = "single"),
    width    = 0.4
  ) +
  scale_fill_manual(
    name   = "Number of Genera",
    values = c(
      "Bacteria" = "#9ECAE1",
      "Archaea"  = "#FC9272",
      "Fungi"    = "#DDA0DD",
      "Protists" = "#A1D99B",
      "Metazoa"  = "#FDBF6F"
    ),
    guide = guide_legend(order = 2)
  ) +
# same settings for rest (makes later cropping and aligning easier)
  theme_bw(base_size = 14) +
  theme(
    axis.text.x     = element_text(angle = 45, hjust = 1),
    legend.position = "right",
    panel.border    = element_blank()
  ) +
  labs(
    x = NULL,
    y = "Relative Abundance (%)"
  ) +
  scale_y_cut(
    breaks = c(5, 85),
    scales = c(1, 1),
    space  = 0.05
  ) +
  expand_limits(y = 102)


# save plots as SVGs
ggsave("Compound_Table_plot.svg", p_broken, 
       width = 10, height = 6, dpi = 300, device = "svg")

ggsave("Compound_Table_dummy_plot.svg",
       p_two_legends, width = 10, height = 6, dpi = 300, device = "svg")