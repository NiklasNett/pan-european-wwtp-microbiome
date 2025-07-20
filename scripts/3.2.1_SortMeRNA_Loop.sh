#!/bin/bash -l

# Author: Niklas Nett
# Created: 2024-11-27
# Last updated: 2025-03-20

# Purpose: Run SortMeRNA on contig-merged FASTA files from Mothur for each ENA accession.
#          Includes optional subsampling, unpacking, and SLURM job submission per sample.
# Input:   - Text file with ENA Run Accession Numbers (one per line)
#          - Compressed FASTA files (one per accession; e.g. *_combined.trim.contigs.fasta.gz)
#          - SLURM batch script for 2.2.2_SortMeRNA_Cheops.sh
# Output:  - Decompressed FASTA copied to temporary folder
#          - SLURM job submission for SortMeRNA with individual output folders per accession
#          - Timestamped log file

# Define directories
InputDir="/scratch/nnett2/mothur_results_italy"
ScratchBaseDir="/scratch/nnett2"

# create directories (if not already existing)
mkdir -p "$InputDir" "$ScratchBaseDir"

# create log file based on start time  
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="/home/nnett2/sortmerna_pipeline_log_${timestamp}.txt"

exec > >(tee -a "$log_file") 2>&1 #copy everything that is shown in terminal into the logfile
echo "Pipeline started at $(date)" > "$log_file"

# Input file --> List with accession numbers
accession_list="/home/nnett2/accession_italy.txt"

# Calculate number of lines in list
total_lines=$(wc -l < "$accession_list")
half_lines=$(( (total_lines + 1) / 2 ))  # Halve the list; round up for odd numbers

# Select mode: To be able to choose what will be processed
echo "What do you want to process?"
echo "1) First half of accession list"
echo "2) Second half of accession list"
echo "3) Enter specific accession number"
read -p "Select Option (1/2/3): " choice

# Access specific accession numbers based on selection
if [[ "$choice" == "1" ]]; then
  accessions=$(head -n "$half_lines" "$accession_list")  # First half of list
elif [[ "$choice" == "2" ]]; then
  accessions=$(tail -n +"$((half_lines + 1))" "$accession_list")  # Second half of list
elif [[ "$choice" == "3" ]]; then
  read -p "Enter accession numbers (separated by spaces): " specific_accessions
  accessions=$(grep -w -F -f <(echo "$specific_accessions" | tr ' ' '\n') "$accession_list")  # Only selected accessions
  echo "Specific accessions selected: $specific_accessions" 
else
  echo "Invalid selection. End script." 
  exit 1
fi

# Loop through selected accessions
for Accession in $accessions; do
    {
        echo "Processing Accession: $Accession"

        # Create directories (unique folder for each accession number - prevent overwriting; each run SortMeRNA generates folders with the same name)
        ScratchInputDir="${ScratchBaseDir}/${Accession}/SortMeRNA_Input"
        ScratchOutputDir="${ScratchBaseDir}/${Accession}/SortMeRNA_Output"
        mkdir -p "$ScratchInputDir"
        mkdir -p "$ScratchOutputDir"

        # Check and move combined Fasta-file
        CombinedFasta="${InputDir}/${Accession}_1_combined.trim.contigs.fasta.gz"
        if [[ ! -f "$CombinedFasta" ]]; then
            echo "Fasta file for $Accession not found. Skipping." 
            continue
        fi
        mv "$CombinedFasta" "$ScratchInputDir/"
        echo "Moving: $CombinedFasta to $ScratchInputDir"

        # Unpack fasta.gz (necessary for SortmeRNA)
        gunzip -f "${ScratchInputDir}/$(basename "$CombinedFasta")"
        UnzippedFasta="${ScratchInputDir}/$(basename "$CombinedFasta" .gz)"
        if [[ ! -f "$UnzippedFasta" ]]; then
            echo "Unpacking error for $Accession. Skipping." 
            continue
        fi
        echo "Unpacked: $UnzippedFasta"

        # start SLURM-Job 
        slurm_out="${ScratchOutputDir}/${Accession}_SortMeRNA_%j.out"
        job_id=$(sbatch --output="$slurm_out" --error="$slurm_out" --job-name="SortMeRNA_${Accession}" \
               /home/nnett2/3.2.2_SortMeRNA_Cheops.sh "$UnzippedFasta" "$ScratchOutputDir" | awk '{print $4}')
        if [[ -z "$job_id" ]]; then
            echo "SLURM job for accession $Accession could not be started!" 
            continue
        fi
        echo "SLURM job for accession $Accession started: Job ID $job_id"
    } >> "$log_file" 2>&1
done

echo "SortmeRNA Loop script completed!"