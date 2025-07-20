#!/bin/bash

# Author: Niklas Nett
# Created: 2025-01-06
# Last updated: 2025-07-20

# Purpose: Download raw FASTQ files from ENA using Accession IDs (supports partial or custom downloads) 
# Input: Text file with ENA Run Accession Numbers (one per line)
# Output: FASTQ files (.fastq.gz) stored in specified directory

# define storage location
download_dir="/home/anna/nas-subdirectory/Niklas/italy_fastq"

# create directory (if not already existing)
mkdir -p "$download_dir"

# Input file --> list with accession numbers
accession_list="accession_italy.txt"

# Calculate number of lines in list
total_lines=$(wc -l < "$accession_list")
half_lines=$(( (total_lines + 1) / 2 ))

# Select mode: To be able to choose what will be downloaded
echo "What do you want to download?"
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
  echo "Specific accessions selected (both reads will be downloaded): $accessions"
elif [[ "$choice" == "4" ]]; then
  read -p "Enter read(s) (space-separated, MUST include _1 or _2): " reads_only
  accessions="$reads_only"
  echo "Specific read(s) selected: $accessions"
else
  echo "Invalid selection. End script."
  exit 1
fi

# Loop through selected accessions (or reads)
for item in $accessions; do
  echo "Processing: $item"

  if [[ "$choice" == "4" ]]; then
    # Option 4: entered read (accession with _1 or _2)
    base_accession="${item%_*}"      # Everything before the underscore
    prefix="${base_accession:0:6}"   # First six characters
    subfolder="0${base_accession: -2}"  # '0' + last two characters
    ftp_url="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${prefix}/${subfolder}/${base_accession}/${item}.fastq.gz"

   # Remove any existing file before downloading (when re-download is needed for replacing corrupted or incomplete files)
    local_file="${download_dir}/${item}.fastq.gz"
    if [[ -f "$local_file" ]]; then
      echo "Removing old file: $local_file"
      if ! rm "$local_file"; then
        echo "Failed to remove $local_file. Exiting."
        exit 1
      fi
    fi

    # downloading file
    wget -P "$download_dir" "$ftp_url" || {
      echo "Download failed for $ftp_url"
      exit 1
    }

  else
    # Options 1, 2, 3: item = accession (no _1 or _2)
    prefix="${item:0:6}"
    subfolder="0${item: -2}"

    url_1="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${prefix}/${subfolder}/${item}/${item}_1.fastq.gz"
    url_2="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${prefix}/${subfolder}/${item}/${item}_2.fastq.gz"

    wget -P "$download_dir" "$url_1"
    wget -P "$download_dir" "$url_2"
  fi

  echo "Downloaded: $item"
done
echo "Downloads completed!"