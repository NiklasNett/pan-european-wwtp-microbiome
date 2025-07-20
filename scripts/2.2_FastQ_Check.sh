#!/bin/bash

# Author: Niklas Nett
# Created: 2024-11-15
# Last updated: 2025-03-20

# Purpose:  Run FastQC on downloaded FASTQ files (supports partial or custom selection)
#           Files are moved to a temporary working directory for processing and returned after quality check
# Input:    - Text file with ENA Run Accession Numbers (one per line)
#           - Corresponding .fastq.gz files stored in input directory
# Output:   - FastQC output (.html and .zip) saved in a specified results folder
#           - Timestamped log file of the run (for debugging and reproducibility)


# Define directories
input_dir="/home/anna/nas-subdirectory/Niklas/italy_fastq" 
working_dir="/home/anna/WorkingDir/Niklas/temp_fastqCheck" 
fastqc_output_dir="/home/anna/nas-subdirectory/Niklas/fastqC_italy" 

# create directories (if not already existing)
mkdir -p "$working_dir" "$fastqc_output_dir"

# create log file (for debugging) based on start time (allows multiple simultaneous runs without overwriting) 
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="/home/anna/WorkingDir/Niklas/fastqc_pipeline_log_${timestamp}.txt" 

exec > >(tee -a "$log_file") 2>&1 # 
echo "Pipeline started at $(date)" 

# Input file --> List with accession numbers
accession_list="/home/anna/WorkingDir/Niklas/accession_italy.txt"

# Define number of threads for FastQC
threads=8

# Calculate number of lines in list
total_lines=$(wc -l < "$accession_list") 
half_lines=$(( (total_lines + 1) / 2 )) 

# Select mode: To be able to choose what will be processed
echo "What do you want to process from: $accession_list?"
echo "1) First half of accession list" 
echo "2) Second half of accession list" 
echo "3) Enter specific accession number (both reads)" 
echo "4) Enter specific read(s) only (MUST include _1 or _2)" 
read -p "Select Option (1/2/3/4): " choice

if [[ "$choice" == "1" ]]; then
  accessions=$(head -n "$half_lines" "$accession_list")
elif [[ "$choice" == "2" ]]; then
  accessions=$(tail -n +"$((half_lines + 1))" "$accession_list")
elif [[ "$choice" == "3" ]]; then
  read -p "Enter accession number(s) (space-separated, WITHOUT _1 or _2): " specific_accessions
  accessions=$(grep -w -F -f <(echo "$specific_accessions" | tr ' ' '\n') "$accession_list")
  echo "Specific accessions selected (both reads will be processed): $accessions"
elif [[ "$choice" == "4" ]]; then
  read -p "Enter read(s) (space-separated, MUST include _1 or _2): " reads_only
  accessions="$reads_only"
  echo "Specific read(s) selected: $accessions"
else
  echo "Invalid selection. End script."
  exit 1
fi

# Main loop: Process each selected accession or read 
for accession in $accessions; do
  if [[ "$accession" =~ _1$ ]]; then
    # Option 4: entered forward read (accession with _1)
    file="${input_dir}/${accession}.fastq.gz" 
    working_file="${working_dir}/${accession}.fastq.gz" 

    # Check if file exists
    if [[ -f "$file" ]]; then
      # if it does, move to working directory (for faster processing)
      mv "$file" "$working_file" && \
      # execute FastQ-Check
      fastqc -o "$working_dir" -t "$threads" "$working_file" && \
      # move results to storage directory
      mv "$working_file" "$file" && \
      mv "${working_dir}/${accession}_fastqc.html" "$fastqc_output_dir" && \
      mv "${working_dir}/${accession}_fastqc.zip" "$fastqc_output_dir" || \
      { echo "Error processing $accession" >&2; continue; }
    else
      echo "File not found: $file"
    fi

  elif [[ "$accession" =~ _2$ ]]; then
    #  Option 4: entered reverse read (accession with _2)
    file="${input_dir}/${accession}.fastq.gz"
    working_file="${working_dir}/${accession}.fastq.gz" 

    # Check if file exists
    if [[ -f "$file" ]]; then
      # if it does, move to working directory (for faster processing)
      mv "$file" "$working_file" && \
      # execute FastQ-Check
      fastqc -o "$working_dir" -t "$threads" "$working_file" && \
      # move results to storage directory
      mv "$working_file" "$file" && \
      mv "${working_dir}/${accession}_fastqc.html" "$fastqc_output_dir" && \
      mv "${working_dir}/${accession}_fastqc.zip" "$fastqc_output_dir" || \
      { echo "Error processing $accession" >&2; continue; }
    else
      echo "File not found: $file"
    fi

  else
    #  Options 1, 2, 3: accession without _1 or _2 --> process both reads
    for read_suffix in "_1" "_2"; do # define read suffix; will first loop for -1; then for _2
      file="${input_dir}/${accession}${read_suffix}.fastq.gz" 
      working_file="${working_dir}/${accession}${read_suffix}.fastq.gz" 

     # Check if file exists
      if [[ -f "$file" ]]; then
        # if it does, move to working directory (for faster processing)
        mv "$file" "$working_file" && \
        # execute FastQ-Check
        fastqc -o "$working_dir" -t "$threads" "$working_file" && \
        # move results to storage directory
        mv "$working_file" "$file" && \
        mv "${working_dir}/${accession}${read_suffix}_fastqc.html" "$fastqc_output_dir" && \
        mv "${working_dir}/${accession}${read_suffix}_fastqc.zip" "$fastqc_output_dir" || \
        { echo "Error processing $accession${read_suffix}" >&2; continue; }
      else
        echo "File not found: $file"
      fi
    done
  fi
done
echo "Pipeline successfully completed."