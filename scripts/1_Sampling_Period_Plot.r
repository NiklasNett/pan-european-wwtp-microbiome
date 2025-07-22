# Author: Niklas Nett
# Created: 2025-04-15
# Last updated: 2025-07-22

# Purpose:   Visualize the sampling periods of all 7 WWTPs as horizontal bars, ordered geographically from north (Copenhagen_RL) to south (Rome)
# Input:     - Manually defined table with plant names and respective start/end dates
# Output:    - Sampling_Periods_Plot.svg (Gantt-style plot showing time coverage per WWTP)

# Load packages
library(tibble)
library(dplyr)
library(ggplot2)
library(lubridate)

# Define directory
setwd("/Users/macniklas/Desktop/MA.ster_2.025/")

# define sampling periods
data <- tribble(
  ~City,          ~Start, ~End,
  "Copenhagen_RL", "27.03.19",  "28.09.20",
  "Copenhagen_RD", "18.02.19",  "28.09.20",
  "Copenhagen_RA", "30.01.19",  "28.09.20",
  "Rotterdam",     "23.04.20",  "03.11.21",
  "Budapest",      "27.07.20",  "17.05.21",
  "Bologna",       "26.11.20",  "27.04.21",
  "Rome",          "26.05.20",  "09.12.20"
)

# convert strings into dates 
data <- data %>%
  mutate(
    Start = dmy(Start),
    End   = dmy(End)
  )

# set order from north (bottom) to south (top) of the cities (else they will be in alphabetical order)
# start by bottom
data$City <- factor(
  data$City,
  levels = c(
    "Rome",
    "Bologna",
    "Budapest",
    "Rotterdam",
    "Copenhagen_RA",
    "Copenhagen_RD",
    "Copenhagen_RL"
  )
)

# set colors
plant_colors <- c(
  "Copenhagen_RL" = "#00BFC4",
  "Copenhagen_RD" = "#00BA38",
  "Copenhagen_RA" = "#7CAE00",
  "Rotterdam"     = "#C77CFF",
  "Budapest"      = "#F564E3",
  "Bologna"       = "#F8766D",
  "Rome"          = "#619CFF"
)

# create plot
p <-  ggplot(data, aes(x = Start, y = City)) +     
  geom_segment(
    aes(xend = End, yend = City, colour = City),
    linewidth = 7 ,
    lineend   = "square"
  ) +
  scale_colour_manual(values = plant_colors) +
  scale_x_date(
    date_breaks = "6 months",
    date_labels = "%b %Y",
    limits = c(as.Date("2019-01-01"), as.Date("2022-04-01"))
  ) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    text          = element_text(family = "Helvetica"),
    axis.text.y   = element_text(face = "bold"),
    axis.text.x   = element_text(angle = 45, hjust = 1),
    legend.position = "none",
    aspect.ratio  = 0.35 
  )

# save plot as svg
ggsave(
  filename = "Sampling_Periods_Plot.svg",
  plot     = p,
  device   = "svg",
  width    = 9,   
  height   = 3    
)