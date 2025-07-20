#!/bin/bash

# Author: Niklas Nett
# Created: 2024-11-20
# Last updated: 2025-03-20

#Purpose: Generate contigs from raw FASTQ files using Mothur and recover non-overlapping forward reads.
#         Includes unpacking, assembling, merging, and cleanup steps (supports partial or custom selection).
# Input:  - Text file with ENA Run Accession Numbers (one per line)
#         - Paired-end FASTQ files (.fastq.gz) for each ENA accession
# Output: - Combined contig and recovered forward-read FASTA files per accession
#         - Mothur contigs report per accession
#         - Timestamped pipeline log file for tracking

#  Define directories
input_dir="/home/anna/nas-subdirectory/Niklas/italy_fastq"
working_dir="/home/anna/WorkingDir/Niklas/mother_run_italy"
output_dir="/home/anna/nas-subdirectory/Niklas/mothur_results_italy"
mothur_path="/home/anna/mothur/mothur"
report_dir="/home/anna/nas-subdirectory/Niklas/mothur_report_italy"

# create directories (if not already existing)
mkdir -p "$working_dir" "$output_dir" "$report_dir"

# create log file (for debugging) based on start time (allows multiple simultaneous runs without overwriting) 
timestamp=$(date +"%Y%m%d_%H%M%S")
log_file="/home/anna/WorkingDir/Niklas/mothur_pipeline_log_${timestamp}.txt"

exec > >(tee -a "$log_file") 2>&1 #copy everything that is shown in terminal into the logfile
echo "Pipeline started at $(date)" > "$log_file"

# Input file --> List with accession numbers
accession_list="/home/anna/WorkingDir/Niklas/accession_italy.txt"

# Minimum required free disk space in GB
min_free_space=20

# Function to check free space in working directory
check_disk_space() {
    local available_space
    available_space=$(df --output=avail -BG "$working_dir" | tail -1 | tr -dc '0-9')

    if (( available_space < min_free_space )); then
        echo "Error: Low disk space (${available_space}GB available, threshold is ${min_free_space}GB). Aborting pipeline." >&2
        exit 1
    fi
}

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

# Loop through selected accession number
for accession in $accessions; do
    {
        echo "Processing Accession: $accession"

        # define filenames for paired-end data (_1 and _2 for each accession)
        file_1="${input_dir}/${accession}_1.fastq.gz"
        file_2="${input_dir}/${accession}_2.fastq.gz"
        working_file_1="${working_dir}/${accession}_1.fastq.gz"
        working_file_2="${working_dir}/${accession}_2.fastq.gz"
        contigs_file="${working_dir}/${accession}_1.trim.contigs.fasta"
        scrap_file="${working_dir}/${accession}_1.scrap.contigs.fasta"
        contigs_report="${working_dir}/${accession}_1.contigs_report"

        # Step 1: Check disk space
        check_disk_space

        # Step 2: Move fastq.gz-file to working directory (for faster processing)
        if [[ -f "$file_1" && -f "$file_2" ]]; then
            mv "$file_1" "$working_file_1"
            mv "$file_2" "$working_file_2"
            echo "Moved ${accession} FASTQ.gz files to $working_dir"
        else
            echo "FASTQ.gz files for $accession not found. Skipping Accession."
            continue
        fi

        # Step 3: Check disk space before unpacking
        check_disk_space

        # Step 4: Unpack the files (necessary for mothur)
        gunzip "$working_file_1" "$working_file_2"
        working_file_1="${working_dir}/${accession}_1.fastq"
        working_file_2="${working_dir}/${accession}_2.fastq"
        echo "Unpacking: $working_file_1 and $working_file_2"

        # Step 5: Check disk space before Mothur
        check_disk_space

        # Step 6: Run Mothur & 
        # set parameters:
        # maxee = maximum allowed error rate (mismatches),
        # maxambig = maximum number of ambiguous bases (N) allowed
        echo "Starting Mothur for $accession"
        mothur_temp_log="${working_dir}/${accession}_mothur_temp_log.txt" #for debugging and monitoring mothur process
        $mothur_path "#set.dir(output=$working_dir);
        make.contigs(ffastq=$working_file_1,
        rfastq=$working_file_2,
        processors=8,
        maxee=1,
        maxambig=1);" > "$mothur_temp_log" 2>&1
        
        # Check if Mothur run was successful
        if [[ ! -s "$contigs_file" ]]; then
            echo "Mothur failed for $accession or no _1.trim.contigs.fasta file was found. Skipping."
            continue
        fi

        # Step 7: Extract non-contiged reads from scrap file
        scrap_txt="${working_dir}/${accession}_scrap.txt"
        grep ">" "$scrap_file" | cut -d " " -f 1 | tr -d ">" > "$scrap_txt"
        if [[ ! -s "$scrap_txt" ]]; then
            echo "The scrap .txt file is empty. Skipping accession $accession."
            continue
        fi

        awk -v acc_prefix="@${accession}" 'NR==FNR {acc[$1]; next} $0 ~ acc_prefix {header=$0; getline seq; getline qheader; getline qseq; id=substr(header, 2, index(header, " ") - 2); if (id in acc) print header"\n"seq"\n"qheader"\n"qseq}' \
        "$scrap_txt" "$working_file_1" > "${working_dir}/filtered_forward_reads_${accession}.fastq"

        if [[ ! -s "${working_dir}/filtered_forward_reads_${accession}.fastq" ]]; then
            echo "The filtered forward reads FASTQ file is empty. Skipping accession $accession."
            continue
        fi

        # Convert filtered non-contiged forward reads to FASTA
        awk 'NR%4==1 {print ">"substr($0, 2)} NR%4==2 {print}' "${working_dir}/filtered_forward_reads_${accession}.fastq" > "${working_dir}/filtered_forward_reads_${accession}.fasta"
        if [[ ! -s "${working_dir}/filtered_forward_reads_${accession}.fasta" ]]; then
            echo "The filtered forward reads FASTA file is empty. Skipping accession $accession."
            continue
        fi
        echo "Extracted forward reads and converted to FASTA."

        # Step 8: Merge FASTA files (by mothur contiged reads & extracted non-contiged forward reads)
        combined_file="${working_dir}/${accession}_1_combined.trim.contigs.fasta"
        cat "$contigs_file" "${working_dir}/filtered_forward_reads_${accession}.fasta" > "$combined_file"
        echo "Combined: $combined_file"

        #  Check if combined file was successfully created
        if [[ ! -s "$combined_file" ]]; then
            echo "Error merging FASTA files. Skipping accession $accession."
            continue
        fi

        # Step 9: Move final file to output directory
        mv "$combined_file" "$output_dir"
        mv "$contigs_report" "$report_dir"
        echo "Moved: $combined_file to $output_dir and $contigs_report to $report_dir"

        # Step 10: Move unpacked FASTQ files and contigs report back to input directory
        mv "$working_file_1" "$input_dir"
        mv "$working_file_2" "$input_dir"
        echo "Moved: $working_file_1, $working_file_2 back to $input_dir"

        # Step 11: Clean up (delete temporary files)
        rm -f "$scrap_file" "$contigs_file" "${working_dir}/filtered_forward_reads_${accession}.fastq" "${working_dir}/filtered_forward_reads_${accession}.fasta" "$scrap_txt" "$mothur_temp_log"
        echo "Cleaned up: Temporary files for $accession deleted."

        echo "$accession completed."
    } >> "$log_file" 2>&1
done

echo "Pipeline completed!" >> "$log_file"