#!/bin/bash -l

# Author: Niklas Nett
# Created: 2024-11-29
# Last updated: 2025-03-20

# Purpose: Submit BLAST jobs to SLURM using either SILVA (prokaryotes) or PR2 (eukaryotes) as reference database (supports partial or custom selection)
# Input:   - Text file with ENA Run Accession Numbers (one per line)
#          - SLURM batch scripts for SILVA and PR2 (3.2_Blast_SILVA.sh / 3.3_Blast_PR2.sh)
# Output:  - Individual SLURM output files per accession and database
#          - Timestamped log file tracking the submission process

# Input file --> List with accession numbers
accession_list=/home/nnett2/accession_italy.txt

# Set paths to sbatch scripts
BlastSILVAScript=/home/nnett2/4.2_Blast_SILVA.sh
BlastPR2Script=/home/nnett2/4.3_Blast_PR2.sh

# create log file based on start time 
log_file="/scratch/nnett2/blast_log_$(date +'%Y%m%d_%H%M%S').log"

exec > >(tee -a "$log_file") 2>&1 #copy everything that is shown in terminal into the logfile
echo "Pipeline started at $(date)" > "$log_file"

# Database selection
echo "Which database do you want to use?"
echo "1) SILVA Prokaryotes"
echo "2) PR2 Eukaryotes"
read -p "Select option (1/2): " db_choice

# Set corresponding batch scripts based on selection
if [[ "$db_choice" == "1" ]]; then
    BatchScript=$BlastSILVAScript
    Database="SILVA"
elif [[ "$db_choice" == "2" ]]; then
    BatchScript=$BlastPR2Script
    Database="PR2"
else
    echo "Invalid selection. Exit script." 
    exit 1
fi
echo "Database selected:: $Database" 

# Calculate number of lines in list
total_lines=$(wc -l < "$accession_list")
half_lines=$(( (total_lines + 1) / 2 ))  # Halve the list; round up for odd numbers

# Select mode: To be able to choose what will be processed
echo "What do you want to process?"
echo "1) All accessions in the list"
echo "2) Enter specific accession number(s)"
read -p "Select Option (1/2): " choice

# Access specific accession numbers based on selection
if [[ "$choice" == "1" ]]; then
    accessions=$(cat "$accession_list")  # Process all accessions
    echo "Processing all accessions in the list."
elif [[ "$choice" == "2" ]]; then
    read -p "Enter accession numbers (separated by spaces): " specific_accessions
    accessions=$(grep -w -F -f <(echo "$specific_accessions" | tr ' ' '\n') "$accession_list")  # Only selected accessions
    if [[ -z "$accessions" ]]; then
        echo "No matching accessions found. Exit script."
        exit 1
    fi
    echo "Specific accessions selected: $specific_accessions"
else
    echo "Invalid selection. End script." 
    exit 1
fi

# Loop through selected accessions
echo "Starting processing for the selected database ($Database) and accessions..." 
while IFS='\n' read -r LINE || [ -n "$LINE" ]; do
    # extract sample name (accession number)
    SampleName=$(echo "$LINE" | cut -d " " -f 1)

    # Define SLURM job names and  output files
    mkdir -p "/scratch/nnett2/blast_results_italy/"
    JobName="${SampleName}_Blast_${Database}"
    SlurmOut="/scratch/nnett2/blast_results_italy/${SampleName}_Blast_${Database}%j.out"

    # Send job for each sample (accession number)
    echo "Submitting job for sample $SampleName to SLURM..." 

    # Start sbatch script for each sample
    sbatch --output="$SlurmOut" --error="$SlurmOut" --job-name="$JobName" \
    "$BatchScript" "$SampleName"
done <<< "$accessions"

echo "BLAST batch script completed" 