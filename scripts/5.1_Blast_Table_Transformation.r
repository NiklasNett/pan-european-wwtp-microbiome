# Author: Niklas Nett
# Created: 2025-01-16
# Last updated: 2025-06-14

# Purpose: Process and filter BLASTN output and transform them into .csv tables (Supports partial or custom selection for each, PR2 and SILVA)
#          Includes taxonomy parsing, renaming, pattern cleanup and export.
# Input:   - Text file with ENA Run Accession Numbers (one per line)
#          - BLASTN result files from PR2 or SILVA (*_rRNA_Blast_P2.txt or *_rRNA_Blast_SIVA.txt)
# Output:  - Cleaned and filtered taxonomy tables (per accession)
#          - Output files in .csv format in selected directory
#          - Timestamped logfile tracking all steps and warnings

# Load packages
library(dplyr)
library(tidyr)
library(stringr)

# Create logfile path
logfile <- paste0("/home/anna/WorkingDir/Niklas/Blast_Processing_Logfile_", format(Sys.time(), "%Y-%m-%d_%H-%M-%S"), ".txt")
log_message <- function(message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- paste0("[", timestamp, "] ", message, "\n")
  cat(log_entry, file = logfile, append = TRUE)
}

log_message("Start script.")

# Input file --> List with accession numbers
accession_list <- "/home/anna/WorkingDir/Niklas/accession_hungary.txt"
accessions <- readLines(accession_list)
log_message(paste("Read:", accession_list, "containing", length(accessions), "accessions."))

# Select Database (PR2 or SILVA) and define specific directories
cat("Which database do you want to use?\n")
cat("1) PR2 (Eukaryotes)\n")
cat("2) SILVA (Prokaryotes)\n")
choice <- as.integer(readline(prompt = "Select option (1/2): "))

if (choice == 1) {
  log_message("PR2 database selected.")
  input_dir <- "/home/anna/nas-subdirectory/Niklas/Blast_PR2_Results_hungary"
  output_dir <- "/home/anna/nas-subdirectory/Niklas/Blast_Liste_PR2_hungary"
  pattern <- "*_rRNA_Blast_P2.txt"
} else if (choice == 2) {
  log_message("SILVA database selected.")
  input_dir <- "/home/anna/nas-subdirectory/Niklas/Blast_SILVA_Results_hungary"
  output_dir <- "/home/anna/nas-subdirectory/Niklas/Blast_Liste_SILVA_hungary"
  pattern <- "*_rRNA_Blast_SILVA.txt"
} else {
  log_message("Invalid option selected. End Process.")
  stop("Invalid option. End script.")
}

# Create directories (if not already existing)
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  log_message(paste("Output directory created:", output_dir))
}

# Select mode: To be able to choose what will be processed
cat("What do you want to process\n")
cat("1) First half of accession list\n")
cat("2) Second half of accession list\n")
cat("3) Enter specific accession number\n")
cat("4) Process all accessions\n")  
accession_choice <- as.integer(readline(prompt = "Select Option (1/2/3/4): "))

# Access specific accession numbers based on selection
if (accession_choice == 1) {
  log_message("Selected first half of accession list.")
  selected_accessions <- accessions[1:(length(accessions) %/% 2)]
} else if (accession_choice == 2) {
  log_message("Selected second half of accession list.")
  selected_accessions <- accessions[(length(accessions) %/% 2 + 1):length(accessions)]
} else if (accession_choice == 3) {
  log_message("Selected to enter specific accession number.")
  specific_accessions <- readline(prompt = "Enter accession numbers (separated by spaces):")
  specific_accessions <- unlist(strsplit(specific_accessions, " "))
  selected_accessions <- accessions[accessions %in% specific_accessions]
  log_message(paste("Specific accessions selected:", length(selected_accessions)))
} else if (accession_choice == 4) {
  log_message("Selected to process all accessions.")
  selected_accessions <- accessions  
} else {
  log_message("Invalid option selected. End Process.")
  stop("Invalid option. End script.")
}

# Filter data based on selection
filenames <- list.files(input_dir, pattern = pattern, full.names = TRUE)
filenames <- filenames[grepl(paste(selected_accessions, collapse = "|"), basename(filenames))]

# Check if selection worked
if (length(filenames) == 0) {
  log_message("Data couldn't be found. End script.")
  stop("Data couldn't be found.")
}

# Start processing (name --> takes on each value from list filenames)
for (name in filenames) {
  tryCatch({
    log_message(paste("Start processing for:", name))  #tryCatch for debugging; detects errors for each iteration of loop (without exiting whole skript)
    
    # Load data and assign columns
    data <- read.delim(name, header = FALSE, sep = "\t", stringsAsFactors = FALSE)
    colnames(data) <- c("ReadID", "ReadLength", "SubjectID_Taxonomy", "Score", 
                        "Evalue", "AlignmentLength", "Identities", "PercentIdentity")
    log_message("Column names successfully assigned.")
    
    # Split up taxonomy column
    data <- data %>%
      mutate(
        SubjectID = str_split_fixed(SubjectID_Taxonomy, "_", 2)[, 1],
        Taxonomy = str_split_fixed(SubjectID_Taxonomy, "_", 2)[, 2]
      )
    taxonomy_columns <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")
    data <- data %>%
      separate(Taxonomy, into = taxonomy_columns, sep = ";", fill = "right")
    log_message("Taxonomy column successfully split.")

    # Delete non-essential columns
    data <- data %>%
      select(ReadID, ReadLength, SubjectID, Domain, Phylum, Class, Order, Family, Genus, Species)
    
    # Filter out specific taxonomies
    data <- data %>%
      filter(!(Class == "Embryophyceae")) %>%
      filter(!(Phylum == "Metazoa" & !Class %in% c("Nematoda", "Rotifera", "Tardigrada")))
    log_message("Data was successfully filtered.")

    # Replace NA values
    data <- data %>%
    mutate(
      Species = ifelse(is.na(Species),
                     ifelse(is.na(Genus),
                            ifelse(is.na(Family),
                                   ifelse(is.na(Order),
                                          paste0(Class, "_XXXX"),
                                          paste0(Order, "_XXX")),
                                   paste0(Family, "_XX")),
                            paste0(Genus, "_X")),
                     Species),
      Genus = ifelse(is.na(Genus),
                   ifelse(is.na(Family),
                          ifelse(is.na(Order),
                                 paste0(Class, "_XXX"),
                                 paste0(Order, "_XX")),
                          paste0(Family, "_X")),
                   Genus),
      Family = ifelse(is.na(Family),
                    ifelse(is.na(Order),
                           paste0(Class, "_XX"),
                           paste0(Order, "_X")),
                    Family),
      Order = ifelse(is.na(Order),
                   paste0(Class, "_X"),
                   Order)
  )
    log_message("NA values successfully replaced.")

    # delete numeric suffixes and correct Aquavolodina column
    taxonomy_columns <- c("Domain", "Phylum", "Class", "Order", "Family", "Genus", "Species")
    data[taxonomy_columns] <- lapply(data[taxonomy_columns], function(column) {
    column <- gsub("_[1-9]|-[1-9]", "", column)
    column <- gsub("Aquavolodina", "Aquavolonida", column)
    return(column)
    })
    log_message("Deleted numeric suffixes.")

# rename specific taxa
data <- data %>%
  mutate(
    Genus = ifelse(Genus == "Lecythium", "Rhogostoma", Genus),
    Family = ifelse(Genus %in% c("Lecythium", "Rhogostoma"), "Rhogostomidae", Family),
    Order = ifelse(Genus %in% c("Lecythium", "Rhogostoma"), "Cryomonadida", Order),
    Family = ifelse(Genus == "UnclassifiedTobrilidae", "Tobrilidae", Family),
    Genus = ifelse(Genus == "UnclassifiedTobrilidae", "Tobrilidae_X", Genus),
    Order = ifelse(Genus == "Rosculus", "Sainouridea", Order),
    Family = ifelse(Family == "Euglyphica_X", "Euglyphida_X", Family),
    Family = ifelse(Family == "Peniculida", "Frontoniidae", Family),
    Genus = ifelse(Genus == "Peniculida_X", "Frontoniidae_X", Genus),
    Family = ifelse(Family == "Phagomyxida_XX", "Phagomyxida_X", Family)
  )
log_message("Specific taxa renamed.")

# Pattern-based replacements
    patterns <- c(".*[Cc]lade.*", ".*[Ll]ineage.*", ".*[Gg]roup.*", ".*[Ll]ike.*", ".*[Nn]ovel-.*", 
                  ".*CONT.*", "OLIGO.*", ".*PHYLL.*", ".*MAST.*", ".*NASSO.*", ".*PLAGI1.*")
    
    replacements <- function(value, higher_level) {
      gsub(paste(patterns, collapse = "|"), paste0(higher_level, "_X"), value)
    }

    for (level in 2:length(taxonomy_columns)) {
      col <- taxonomy_columns[level]
      higher_col <- taxonomy_columns[level - 1]
      data[[col]] <- mapply(function(value, higher) {
        if (grepl(paste(patterns, collapse = "|"), value)) {
          replacements(value, higher)
        } else if (value == higher) {
          paste0(higher, "_X")
        } else {
          value
        }
      }, data[[col]], data[[higher_col]])
    }
    
    log_message("Pattern-based replacements applied.")

# rename endosymbiont and uncultured-taxonomies 
data <- data %>%
  mutate(
    Genus = ifelse(grepl("endosymbiont", Genus), paste0("endosymbiontic ", Family), Genus),
    Genus = ifelse(Genus == "uncultured", paste0("uncultured ", Family), Genus),
    Genus = ifelse(Genus == "unculturedX", paste0("uncultured ", Order, "X"), Genus),
    Family = ifelse(Genus == "unculturedX", paste0("uncultured ", Order), Family),
    Genus = ifelse(Genus == "unculturedXX", paste0("uncultured ", Class, "XX"), Genus),
    Family = ifelse(Genus == "unculturedXX", paste0("uncultured ", Class, "X"), Family),
    Order = ifelse(Genus == "unculturedXX", paste0("uncultured ", Class), Order)
  )
log_message("Renamed endosymbiont and uncultured-taxonomies.")

# binning Rhogostoma
data <- data %>%
  mutate(Genus = ifelse(Genus %in% c("Rhogostoma", "Rhogostomidae_X", "Capsellina", "Sacciforma"), "Rhogostoma", Genus))
    
    # Save data (as CSV table)
    base_name <- tools::file_path_sans_ext(basename(name))
    output_file <- file.path(output_dir, paste0(base_name, "_filtered.csv"))
    write.csv(data, output_file, row.names = FALSE)
    log_message(paste("Data successfully processed and saved:", output_file))
    
  }, error = function(e) {
    log_message(paste("Error during processing of:", name, "Details:", e$message)) #Logs errors caught by tryCatch
  })
}

log_message("Finished processing for all selected accessions.")